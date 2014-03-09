#node_modules
express = require 'express'
mongoose = require 'mongoose'
restify = require 'restify'
fs = require 'fs'

#custom JS modules
question = require './controllers/question'
message = require './controllers/message'
config = require './config'

#create REST server
app = restify.createServer()
app.use restify.bodyParser
	mapParams: false
app.use restify.queryParser()

#DB stuff
mongoose.connect config.database.machine + ':' + config.default.port + '/' + config.database.DBName
db = mongoose.connection

db.on 'error', console.error.bind console, 'connection error'

#TODO: App won't start if db connection cannot be opened
db.once 'open', () ->
	app.post '/question/insert', question.insert
	app.get '/question', question.all	
	app.get '/messages', message.all
	app.post '/messages/insert', message.insert
	app.post '/messages/incoming', message.incomingListener
	app.post '/question/update', question.update
	app.listen 3000
