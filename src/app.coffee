# Requires
require "coffee-script/register" # Needed for .coffee modules
require "longjohn" if process.env.NODE_ENV isnt "production"
require "log-timestamp"

express = require "express"

# Lib classes
__ = require "#{ __dirname }/../lib/__"

# Determine config
config = __.config()

app = express()
http = require("http").Server(app)
io = require("socket.io")(http)

# Express settings
app.use require("compression")()
app.use require("body-parser").json()
app.set 'json spaces', 2

# Datastore
save = require("save")

Messages = save("messages")
Users = save("users")
Tokens = save("tokens")

# ROOT
# ====
app.get "/", (req, res) ->
  res.json
    status: 200
    spec: "https://github.com/ryanbrodie/Briefly"

# AUTHORISATION
# =============

# Auth middleware for easy token validation
auth = (req, res, next) ->
  if not req.query? or not req.query.token?
    err = new Error("Access forbidden; no valid access token provided.")
    err.sendStatus = 401
    next err

  Tokens.findOne { token: req.query.token }, (err, token) ->
    req.token = token.token
    req.username = token.username
    next()

# Bad access handler
unauthorized = (res) ->
  res.set "WWW-Authenticate", "Basic realm=Authorization Required"
  res.sendStatus 401

# Authorisation request
# --------------------
app.post "/auth", (req, res, next) ->
  user = require("basic-auth")(req)

  return unauthorized(res) if not user or not user.name or not user.pass

  Users.findOne { username: user.name, password: user.pass }, (err, user) ->
    return unauthorized(res) if user is undefined

    Tokens.findOne { username: user.username }, (err, token) ->
      if token isnt undefined
        return res.json(token)

      token =
        token: require('rand-token').generate(16),
        username: user.username

      Tokens.create token, (err, token) ->
        return res.json(token)


# Deauthorisation request
# -----------------------
app.delete "/auth", auth, (req, res, next) ->
  Tokens.findOne { token: req.token }, (err, token) ->
    if token is undefined
      err = new Error("Valid token not found")
      err.sendStatus = 400
      return next err

    Token.deleteMany { token: req.query.token }, (err) ->
      return res.json({ success: "Token destroyed" })

# MESSAGE PASSING
# ===============

# Create message
# --------------
app.post "/message", auth, (req, res, next) ->
  if not req.body? or not req.body.message?
    err = new Error("No message provided")
    err.sendStatus = 400
    return next err

  message =
    message: req.body.message
    from: req.username
    at: Date.now()

  Messages.create message, (err, message) ->
    res.json message

# Get recent messages
# -------------------
app.get "/messages", auth, (req, res, next) ->
  Messages.find {}, (err, messages) ->
    res.json messages

# USERS
# =====

# Create user
# -----------
app.post "/user", (req, res, next) ->
  if not req.body? or not req.body.username? or not req.body.password?
    err = new Error("Missing username or password")
    err.status = 400
    return next err

  Users.findOne { username: req.body.username }, (err, user) ->
    if user isnt undefined
      err = new Error("User already exists with that username")
      err.status = 400
      return next err

    user =
      username: req.body.username
      password: req.body.password

    Users.create user, (err, user) ->
      return next res.json({ success: "User created" })

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
# Isn't working?
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