mongoose = require 'mongoose'
Schema = mongoose.Schema

MessageSchema = new Schema
	source: 
		type: String
		required: true
	destination:
		type: String
		required: true
	question: 
		type: Schema.Types.ObjectId
		ref: 'Question'
	time:
		type: Date
		required: true
	messageId:
		type: String
		required: true

Message = mongoose.model 'Message', MessageSchema

