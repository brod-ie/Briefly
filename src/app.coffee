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
app.use require("body-parser").json({ strict: false })
app.set 'json spaces', 2

# Fix json error
app.use (req, res, next) ->
  req.body = JSON.parse req.body if typeof req.body is "string"
  next()

# Datastore
save = require("save")

Messages = save("messages")
Users = save("users")
ActiveUsers = save("active_users")
Tokens = save("tokens")

# LOADERIO VERIFICATION
# =====================
app.get "/loaderio-fa1db6b2da5f4b83300113acc45c8a06/", (req, res) ->
  res.send "loaderio-fa1db6b2da5f4b83300113acc45c8a06"

# ROOT
# ====
app.get "/", (req, res) ->
  res.json
    status: 200
    spec: "https://github.com/ryanbrodie/Briefly"

# AUTHORISATION
# =============

# Bad access handler
unauthorized = (res) ->
  res.set "WWW-Authenticate", "Basic realm=Authorization Required"
  res.sendStatus 401

# Auth middleware for easy token validation
auth = (req, res, next) ->
  if not req.query? or not req.query.token?
    return unauthorized res

  Tokens.findOne { token: req.query.token }, (err, token) ->
    return unauthorized res if token is undefined
    req.token = token.token
    req.username = token.username
    next()

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
        token: require('rand-token').generate(16)
        username: user.username

      token.token = "abcde" if user.username is "brodie"

      Tokens.create token, (err, token) ->
        return res.json(token)

# Deauthorisation request
# -----------------------
app.delete "/auth", auth, (req, res, next) ->
  Tokens.deleteMany { token: req.token }, (err) ->
    return res.json({ success: "Token destroyed" })

# MESSAGE PASSING
# ===============

# Create message
# --------------
app.post "/message", auth, (req, res, next) ->
  if not req.body? or not req.body.message?
    err = new Error("No message provided")
    err.status = 400
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
      res.json({ success: "User created" })

# Get active users
# ----------------
app.get "/users/active", auth, (req, res, next) ->
  ActiveUsers.find {}, (err, users) ->
    res.json users

# ERROR HANDLING
# ==============

# Not found
app.use (req, res, next) ->
  err = new Error("Not found")
  err.status = 404
  next err

# Error handler fn
app.use (err, req, res, next) ->
  res.status err.status or 500
  res.json
    error: err.message

# REAL TIME API
# =============

# Validate connection
io.use (socket, next) ->
  # Parse URL
  u = require("url").parse socket.handshake.url, true

  if not u.query? or not u.query.token?
    console.log "Bad Socket.IO connection attempt"
    return socket.disconnect()

  # Testing token
  if u.query.token is "abcde"
    socket.username = "brodie"
    return next()

  Tokens.findOne { token: u.query.token }, (err, token) ->
    return socket.disconnect() if token is undefined
    socket.username = token.username
    next()

io.on "connection", (socket) ->
  ActiveUsers.create { username: socket.username }, (err, user) ->
    console.log "#{ user.username } connected!"

  socket.on "disconnect", (socket) ->
    # Remove socket.id from array?
    ActiveUsers.delete { username: socket.username }, (err) ->
      console.log "#{ user.username } disconnected"

# On new message
Messages.on "create", (message) ->
  io.emit "message", message

emitActiveUser = (io) ->
  ActiveUsers.find {}, (err, users) ->
    io.emit "users/active", users

ActiveUsers.on "create", (user) ->
  emitActiveUser(io)

ActiveUsers.on "delete", (user) ->
  emitActiveUser(io)

# Run server and return object
# ============================
return server = http.listen config.PORT, ->
  console.log "👂  Listening on port %d", server.address().port