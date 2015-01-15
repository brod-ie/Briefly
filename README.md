[![Build Status](https://travis-ci.org/ryanbrodie/Briefly.svg?branch=master)](https://travis-ci.org/ryanbrodie/Briefly)

# Briefly

## Approach
Test driven development - always!

We chose to have to distinct repositories due to the nature of Travis CI running *all* tests on push which would prove problematic.

Bottleneck for Matt with the server needing to be built or spec finalised.

### Plan of development

1. Finalise spec
2. Write tests
3. Develop
4. Release

### Testing methodology
Server:
- Unit testing
- Load.io testing (how the server scales)
- Code coverage
- Coffeescript linting and reporting

Client:
- Unit testing
- Front end testing

## RESTful API

This API is used for app initialisation (authorising user, getting latest messages, retrieving current active users) as well as creating new messages and deauthorising the session.

### Account creation

    curl -X POST -H "Content-Type: application/json" -d '{"username":"brodes","password":"password"}' \
    https://briefly-chat.herokuapp.com/user

Username must be unique, password is stored unencrypted. If successful a success object is returned:

    {
        success: "User created"
    }

### Authorisation

    curl -X POST -u 'username:pass' https://briefly-chat.herokuapp.com/auth

Returns a unique token if valid:

    {
        token: "12345",
        username: "brodie"
    }

### Deauthorisation

    curl -X DELETE https://briefly-chat.herokuapp.com/auth?token=12345

Returns a success object if successful:

    {
        success: "Invalidated token"
    }

### Create message

    curl -X POST -H "Content-Type: application/json" -d '{"message":"Hello world!"}' \
    https://briefly-chat.herokuapp.com/message?token=12345

Returns message object if successful:

    {
        message: "Hello world!",
        at: 1420025338,
        from: "brodie"
    }

### Get messages

    curl -X GET https://briefly-chat.herokuapp.com/messages?token=12345

Returns last 10 messages (array of message objects) if successful.

### Get active users

    curl -X GET https://briefly-chat.herokuapp.com/users/active?token=12345

Returns an array of user objects of active users. These users are deemed active based on whether they are connected to the Real Time API with a valid access token.

## Real Time API

This API should only be used to provide Real Time updates to the client. When connected using a valid token the user will be marked as active. On disconnection or deauthorisation the user in question will be marked as inactive.

### Connecting

    SocketIO.connect "https://briefly-chat.herokuapp.com/?token=abcdefgh"

### New message event

    SocketIO.on "message", (data) ->

Where `data` is a valid message object.

### Active users change event

    SocketIO.on "users/active", (data) ->

Where `data` is an array of user objects.