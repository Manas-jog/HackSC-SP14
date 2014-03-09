
mongoose = require 'mongoose'
Schema = mongoose.Schema

QuestionSchema = new Schema
	question:
		type: String,
		required: true
	answer: String

Question = mongoose.model 'Question', QuestionSchema

