# Requires
__ = require "#{ __dirname }/../lib/__"
frisby = require "frisby"

# Determine config
config = __.config()

describe "Authentication", ->
  server = require "#{ __dirname }/../app/app"

  it 'can return an access token for valid user', ->
    frisby
      .create("Ensure test")
      .post("http://localhost:#{ config.PORT }/v1.0/auth")
      .expectJSON
        Hi: "auth"
      .toss()

  afterEach ->
    setTimeout ->
      server.close()
    , 1000