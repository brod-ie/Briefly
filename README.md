[![Build Status](https://travis-ci.org/ryanbrodie/Briefly.svg?branch=master)](https://travis-ci.org/ryanbrodie/Briefly)

# Briefly

> Server component of G53SQM 14/15 coursework

## RESTful API

This API is used for app initialisation (authorising user, getting latest messages, retrieving current active users) as well as creating new messages and deauthorising the session.

### Account creation
```bash
curl -X POST -H "Content-Type: application/json" -d '{"username":"brodes","password":"password"}' \
https://briefly-chat.herokuapp.com/user
```
Username must be unique, password is stored unencrypted. If successful a success object is returned:
```json
{
    success: "User created"
}
```
### Authorisation
```bash
curl -X POST -u 'username:pass' https://briefly-chat.herokuapp.com/auth
```

Returns a unique token if valid:
```json
{
    token: "12345",
    username: "brodie"
}
```

### Deauthorisation

```bash
curl -X DELETE https://briefly-chat.herokuapp.com/auth?token=12345
```

Returns a success object if successful:

```json
{
    success: "Invalidated token"
}
```

### Create message

```bash
curl -X POST -H "Content-Type: application/json" -d '{"message":"Hello world!"}' \
https://briefly-chat.herokuapp.com/message?token=12345
```

Returns message object if successful:

```json
{
    message: "Hello world!",
    at: 1420025338,
    from: "brodie"
}
```

### Get messages

```bash
curl -X GET https://briefly-chat.herokuapp.com/messages?token=12345
```

Returns last 10 messages (array of message objects) if successful.

### Get active users

```bash
curl -X GET https://briefly-chat.herokuapp.com/users/active?token=12345
```

Returns an array of user objects of active users. These users are deemed active based on whether they are connected to the Real Time API with a valid access token.

## Real Time API

This API should only be used to provide Real Time updates to the client. When connected using a valid token the user will be marked as active. On disconnection or deauthorisation the user in question will be marked as inactive.

### Connecting

```coffeescript
SocketIO.connect "https://briefly-chat.herokuapp.com/?token=abcdefgh"
```
### New message event

```coffeescript
SocketIO.on "message", (data) ->
```

Where `data` is a valid message object.

### Active users change event
```coffeescript
SocketIO.on "users/active", (data) ->
```
Where `data` is an array of user objects.
