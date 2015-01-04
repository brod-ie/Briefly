# Requires
__ = require "#{ __dirname }/../lib/__"

# Determine config
config = __.config()

describe 'SocketIO', ->
  # RUBBISH!
  # Make this run ./app/app.js after build
  # then test connection..

  io = require "socket.io-client"
  socketURL = "http://onin.herokuapp.com"
  options =
    transports: ["websocket"]
    "force new connection": true

  connected = false
  beforeEach (done) ->
    client = io.connect socketURL, options
    client.on "connect", (data) ->
      console.log "connected!"
      connected = true
      done()

  it 'Client can connect to SocketIO', ->
    expect(connected).toBe(true)

describe 'Database', ->
  # db = null
  # collection = "testing"
  # key = 12345

  # it 'can connect to Orchestrate', ->
  #   db = require("orchestrate")(config.ORCHESTRATE_TOKEN)

  # it 'can insert a record', ->
  #   db.put(collection, key,
  #     name: "Steve Kaliski"
  #     hometown: "New York, NY"
  #     twitter: "@stevekaliski"
  #   ).then((result) ->
  #     key = (result.headers.location.split "/")[3]
  #     expect(key).toMatch key
  #   ).fail (err) ->
  #     throw err

  # it 'can retrieve a record', ->
  #   db.get(collection, key)
  #   .then((result) ->
  #     console.log result.body
  #   ).fail (err) ->
  #     throw err

  # it 'can update a record', ->

  # it 'can delete a record', ->

describe 'Authentication', ->