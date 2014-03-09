twilio = require 'twilio'

mongoose = require 'mongoose'
q = require '../models/question'
m = require '../models/message'
ObjectId = mongoose.Types.ObjectId

Question = mongoose.model 'Question'
Message = mongoose.model 'Message'

exports.all = (req, res, next) ->
	Question.find().select('question answer').exec (err, questions) ->
		if err
			return next err
		else
			output = 
				Questions: questions
			res.send output

exports.insert = (req, res, next) ->	
	question = new Question
		question: req.body.question
		answer: req.body.answer

	question.save (err) ->
		if err
			return next err
		else
			res.send question


exports.update = (req, res, next) ->
	questionId = req.body.id

	Message.find
		'question': questionId
	.populate('question').select('question source destination').exec (err, messages) ->
		if err
			return next err
		else
			console.log messages
			messages.forEach (message, index, messages) ->
				destination = message.source
				source = message.destination				
				accountSid = "ACfaa9a45e4f94940cee4d879837d92761"
				authtoken = "330fc8bcc245be6475447062f80bc899"

				client = new twilio.RestClient accountSid, authtoken

				client.sms.messages.create
					to: destination,
					from: source,
					body: req.body.answer
				, (err, message) ->
					if not err
						console.log message.sid
					else
						console.log 'OOPS!'

	Question.update
		_id: questionId
	,
		answer: req.body.answer
	,
		multi: true
	,  (err, numAffected, response) ->
		if err
			next err
		else
			res.send response
