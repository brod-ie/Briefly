# Requires
require "coffee-script/register" # Needed for .coffee modules
require "longjohn" if process.env.NODE_ENV isnt "production"
require "log-timestamp"

__ = require "#{ __dirname }/../lib/__"
express = require "express"
compress = require("compression")()
basicAuth = require "basic-auth"

# Determine config
config = __.config()

app = express()
http = require("http").Server(app)
io = require("socket.io")(http)

# Express settings
app.use compress
app.set 'json spaces', 2

# ROOT
# ====
app.get "/", (req, res) ->
  res.json
    status: 200
    spec: "https://stackedit.io/editor#!provider=couchdb&id=1Iagla7H8vNH969Gd1puJQD6"

# AUTHORISATION
# =============

# Auth middleware for easy token validation
auth = (req, res, next) ->
  if not req.query.token?
    err = new Error("Access forbidden; no valid access token provided.")
    err.sendStatus = 401
    next err

  console.log req.query.token
  req.token = req.query.token
  next()

# Bad access handler
unauthorized = (res) ->
  res.set "WWW-Authenticate", "Basic realm=Authorization Required"
  res.send 401

# Authorisation request
# --------------------
app.post "/auth", (req, res, next) ->
  user = basicAuth(req)

  return unauthorized(res) if not user or not user.name or not user.pass

  if user.name is "foo" and user.pass is "bar"
    res.json
      Hello: "foo"
  else
    unauthorized(res)

# Deauthorisation request
# -----------------------
app.delete "/auth", auth, (req, res, next) ->
  res.json req.token

# MESSAGE PASSING
# ===============

# Create message
# --------------
app.post "/message", auth, (req, res, next) ->
  res.json req.token

# Get recent messages
# -------------------
app.get "/messages", auth, (req, res, next) ->
  # e.g. find where timestamp < 1 week

# USERS
# =====

# Get active users
# ----------------
app.get "users/active", auth, (req, res, next) ->

# ERROR HANDLING
# ==============

# Not found
app.use (req, res, next) ->
  err = new Error("Not found")
  err.status = 404
  next err

# Force https connection
app.use (req, res, next) ->
  if req.protocol isnt "https" and config.ENVIRONMENT isnt "local"
    err = new Error("You must connect using https")
    err.status = 400
    next err

# Error handler fn
app.use (err, req, res, next) ->
  console.log err
  res.status err.status or 500
  res.json
    error: err.message

# REAL TIME API
# =============

# Validate connection
io.use (socket, next) ->
  # Parse URL
  u = require("url").parse socket.handshake.url, true

  if u.query.token isnt "12345"
    socket.disconnect()
  else
    next()


io.on "connection", (socket) ->
  # Store socket.id internally as active?
  console.log "A user connected!"

  socket.on "disconnect", (socket) ->
    # Remove socket.id from array?
    console.log "A user disconnected :("

# Run server and return object
# ============================
return server = http.listen config.PORT, ->
  console.log "👂  Listening on port %d", server.address().port