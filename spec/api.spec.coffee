# Requires
__ = require "#{ __dirname }/../lib/__"
frisby = require "frisby"
io = require "socket.io-client"

# Determine config
config = __.config()

describe "API Server", ->
  server = require "#{ __dirname }/../app/app"
  username = "brodie"
  password = "password"
  token = 12345 # Dummy token accepted by API for username "brodie"

  # client = io.connect "http://localhost:#{ config.PORT }?token=12345"
  # client.on "connect", (data) ->
  #   console.log "connected!"
  #   connected = true

  REST API
  frisby
    .create "REST API can be reached"
    .get "http://localhost:#{ config.PORT }"
    .expectStatus 200
    .expectJSON
      status: 200
    .toss()

  frisby
    .create "REST API can return an error for bad endpoints"
    .get "http://localhost:#{ config.PORT }/jksjckjks"
    .expectStatus 404
    .expectJSON
      error: "Not found"
    .toss()

  frisby
    .create "REST API can create unique user"
    .post "http://localhost:#{ config.PORT }/user", { username: username, password: password }, { json: true }
    .expectStatus 200
    .expectJSON
      success: "User created"
    .toss()

  frisby
    .create "REST API can prohibit duplicate users"
    .post "http://localhost:#{ config.PORT }/user", { username: username, password: password }, { json: true }
    .expectStatus 400
    .expectJSON
      error: "User already exists with that username"
    .toss()

  frisby
    .create "REST API can determine missing credentials on user create"
    .post "http://localhost:#{ config.PORT }/user", {}, { json: true }
    .expectStatus 400
    .expectJSON
      error: "Missing username or password"
    .toss()

  frisby
    .create "REST API can deny access to an invalid user"
    .post "http://fool:bart@localhost:#{ config.PORT }/auth"
    .expectStatus 401
    .toss()

  frisby
    .create "REST API can return an access token for valid user"
    .post "http://#{ username }:#{ password }@localhost:#{ config.PORT }/auth"
    .expectStatus 200
    .toss()

  # it 'can accept new message with valid token', ->

  # it 'Client can connect to SocketIO', ->
  #   #expect(connected).toBe true

  # it 'Can fail..', ->
  #   #expect(true).toBe false

  # it 'can be connected to with a valid access token', ->

  # it 'can error when connected to with invalid access token', ->

  # it 'can recieve a new message', ->

  # it 'can '

  # it 'can emit array of connected users on new connection', ->

  # it 'can emit array of messages on new message', ->

  # it 'can emit array of messages and users to new connection', ->

  # Timeout server now complete
  afterEach ->
    setTimeout ->
      server.close()
    , 1000