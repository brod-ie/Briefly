# Requires
__ = require "#{ __dirname }/../lib/__"

# Determine config
config = __.config()

describe "SocketIO", ->
  # RUBBISH!
  # Make this run ./app/app.js after build
  # then test connection..

  # io = require "socket.io-client"
  # socketURL = "http://onin.herokuapp.com"
  # options =
  #   transports: ["websocket"]
  #   "force new connection": true

  # connected = false
  # beforeEach (done) ->
  #   client = io.connect socketURL, options
  #   client.on "connect", (data) ->
  #     console.log "connected!"
  #     connected = true
  #     done()

  # it 'Client can connect to SocketIO', ->
  #   expect(connected).toBe true

  # it 'Can fail..', ->
  #   expect(true).toBe false