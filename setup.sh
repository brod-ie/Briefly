#!/usr/bin/env bash

curl -X POST -H "Content-Type: application/json" -d '{"username":"brodie","password":"password"}' https://briefly-chat.herokuapp.com/user
curl -X POST https://brodie:password@briefly-chat.herokuapp.com/auth
curl -X POST -H "Content-Type: application/json" -d '{"message":"Hello world!"}' https://briefly-chat.herokuapp.com/message?token=abcde
curl -X GET https://briefly-chat.herokuapp.com/messages?token=abcde