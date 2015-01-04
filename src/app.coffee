# Requires
require "coffee-script/register" # Needed for .coffee modules

__ = require "#{ __dirname }/../lib/__"
express = require "express"
compress = require("compression")()

# Determine config
config = __.config()

app = express()
http = require("http").Server(app)
io = require("socket.io")(http)

# Express settings
app.use compress
app.set 'json spaces', 2

# Error handling
app.use (err, req, res, next) ->
  console.error err.stack
  res.status(500).send "Something broke!"

# Redirect to versioned endpoint
app.use (req, res, next) ->
  whole = req.path.indexOf "/v1.0"
  decimal = req.path.indexOf "/v1"

  if whole is -1 and decimal is -1
    res.redirect "/v1.0#{ req.path }"
  else
    next()

router = express.Router()

router.get "/", (req, res) ->
  res.json
    Hello: "World"

router.get "/test", (req, res) ->
  res.json
    Hello: "Brodie"

app.use '/v1.0/', router
app.use '/v1/', router

# Socket.IO
io.on "connection", (socket) ->
  console.log "A user connected!"
  io.emit "message", { "message": "hello!", "id": socket.id }

io.on "auth", (data) ->
  console.log data

# Run server
server = http.listen config.PORT, ->
  console.log "👂  Listening on port %d", server.address().port