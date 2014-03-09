twilio = require 'twilio'

http = require 'http'

mongoose = require 'mongoose'
m = require '../models/message'
q = require '../models/question'
ObjectId = mongoose.Types.ObjectId

Question = mongoose.model 'Question'
Message = mongoose.model 'Message'

AddMessageToDB = (messageContent, req, res, question_id = "") ->
	console.log 'questid:' + question_id
	questionObj = null
	saveQuestion = false

	if question_id == ""
		questionObj = new Question
			question: messageContent
			answer: ""
		question_id = questionObj._id.toString()
		saveQuestion = true

	console.log 'finalid:' + question_id

	message = new Message
		source: req.body.From
		destination: req.body.To
		question: question_id #Will this be an objectid?
		time: Date.now()
		messageId: req.body.SmsMessageSid

	if saveQuestion 
		console.log 'hi1'
		questionObj.save (err) ->
			if err
				console.log err
				return next err
			else
				message.save (err) ->
					if err
						console.log err
						return next err
					else
						res.send message				
	else
		console.log 'hi2'
		message.save (err) ->
			if err
				console.log err
				return next err
			else
				res.send message	

exports.incomingListener = (req, res, next) ->
	messageContent = req.body.Body

	Question.find().exec (err, questions) ->
		if err
			console.log 'oh no!'
		else
			done = false
			counter = questions.length

			if counter == 0
				done = true
				AddMessageToDB(messageContent, req, res)
						
			questions.forEach (question, index, questions) ->
				if not done
					url = "http://www.tools4noobs.com/ajax_string_similarity?text="
					text1 = encodeURI messageContent
					text2 = encodeURI question
					url = url + text1 + '&text2=' + text2 + '&limit=0.0'

					http.get url, (resp)->
						responseText = ""
						resp.on 'data', (chunk)->
							responseText += chunk
						resp.on 'end', () ->
							if not done
								confidence = (responseText.match /\d+\.\d+/g)[0]
								similarity = parseFloat confidence
								console.log similarity

								if similarity > 30.0

									if question.answer != ""
										console.log 'need to send answer as:' + question.answer
										destination = req.body.From
										source = req.body.To				
										accountSid = "ACfaa9a45e4f94940cee4d879837d92761"
										authtoken = "330fc8bcc245be6475447062f80bc899"

										client = new twilio.RestClient accountSid, authtoken

										client.sms.messages.create
											to: destination,
											from: source,
											body: question.answer
										, (err, message) ->
											if not err
												console.log message.sid
											else
												console.log 'OOPS!'

									else
										AddMessageToDB(messageContent, req, res, question._id)
									done = true
									res.send 'Success'
									return
								else
									counter -= 1

								if counter == 0 #all scanned!!
									done = true
									AddMessageToDB(messageContent, req, res)
						
exports.all = (req, res, next) ->
	lastAccessedTime = new Date req.params.lastAccessedTime #new Date('2011-04-11T11:51:00')

	Message.find().exec (err, messages) ->
		if err
			return next err
		else
			output =
				messages: messages
			res.send output

exports.insert = (req, res, next) ->
	
	questionObj = new Question
		question: req.body.question.question
		answer: req.body.question.answer

	message = new Message
		source: req.body.source
		destination: req.body.destination
		question: questionObj._id
		time: Date.now()

	questionObj.save (err) ->
		if err
			return next req
		else
			message.save (err) ->
				if err
					return next err
				else
					res.send message