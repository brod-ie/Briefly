# Requires
__ = require "#{ __dirname }/../lib/__"
frisby = require "frisby"
io = require "socket.io-client"
AsyncSpec = require "node-jasmine-async"

# Determine config
config = __.config()
server = require "#{ __dirname }/../app/app" # Server on localhost:5000
username = "brodie"
password = "password"
token = "abcde" # Dummy token accepted by API for username "brodie"

describe "API Server", ->

  # REST API
  # ========
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

  # USER CREATION
  # -------------
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

  # AUTHORISATION
  # -------------
  frisby
    .create "REST API can deny access to an invalid user"
    .post "http://fool:bart@localhost:#{ config.PORT }/auth"
    .expectStatus 401
    .toss()

  frisby
    .create "REST API can return an access token for valid user"
    .post "http://#{ username }:#{ password }@localhost:#{ config.PORT }/auth"
    .expectStatus 200
    .expectJSON
      token: token
    .toss()

  # set up the async spec
  async = new AsyncSpec(this)
  client = null

  # run an async setup
  async.beforeEach (done) ->
    client = io.connect "http://localhost:#{ config.PORT }?token=#{ token }"
    done()

  # run an async expectation
  async.it "recieved new message event", (done) ->
    client.on "message", (message) ->
      expect(message.message).toBe "Hello world!"
    done()

  async.it "recieved users/active event", (done) ->
    client.on "users/active", (users) ->
      expect(users).toBe(jasmine.any(Object))
    done()

  # MESSAGES
  # --------
  frisby
    .create "REST API can create a new message"
    .post "http://localhost:#{ config.PORT }/message?token=#{ token }", { message: "Hello world!" }, { json: true }
    .expectStatus 200
    .expectJSON
      message: "Hello world!"
      from: username
    .toss()

  frisby
    .create "REST API can determine missing credentials on message create"
    .post "http://localhost:#{ config.PORT }/message?token=#{ token }", {}, { json: true }
    .expectStatus 400
    .expectJSON
      error: "No message provided"
    .toss()

  frisby
    .create "REST API can retrieve all messages"
    .get "http://localhost:#{ config.PORT }/messages?token=#{ token }"
    .expectStatus 200
    .toss()

  # ACTIVE USERS
  # ------------
  frisby
    .create "REST API can return active users"
    .get "http://localhost:#{ config.PORT }/users/active?token=#{ token }"
    .expectStatus 200
    .toss()

  # DEAUTHORISATION
  # ---------------
  frisby
    .create "REST API can deauthorise token"
    .delete "http://localhost:#{ config.PORT }/auth?token=#{ token }"
    .expectStatus 200
    .expectJSON
      success: "Token destroyed"
    .toss()

  frisby
    .create "REST API can reject invalid token deauthorisation"
    .delete "http://localhost:#{ config.PORT }/auth?token=12345"
    .expectStatus 401
    .toss()

  # Timeout server now complete
  afterEach (done) ->
    setTimeout ->
      # Disconnect Socket.IO first
      client.disconnect()
      # Then close server
      setTimeout ->
        server.close()
      , 1000
    , 500
    done()