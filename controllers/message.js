// Generated by CoffeeScript 1.7.1
var AddMessageToDB, Message, ObjectId, Question, http, m, mongoose, q, twilio;

twilio = require('twilio');

http = require('http');

mongoose = require('mongoose');

m = require('../models/message');

q = require('../models/question');

ObjectId = mongoose.Types.ObjectId;

Question = mongoose.model('Question');

Message = mongoose.model('Message');

AddMessageToDB = function(messageContent, req, res, question_id) {
  var message, questionObj, saveQuestion;
  if (question_id == null) {
    question_id = "";
  }
  console.log('questid:' + question_id);
  questionObj = null;
  saveQuestion = false;
  if (question_id === "") {
    questionObj = new Question({
      question: messageContent,
      answer: ""
    });
    question_id = questionObj._id.toString();
    saveQuestion = true;
  }
  console.log('finalid:' + question_id);
  message = new Message({
    source: req.body.From,
    destination: req.body.To,
    question: question_id,
    time: Date.now(),
    messageId: req.body.SmsMessageSid
  });
  if (saveQuestion) {
    console.log('hi1');
    return questionObj.save(function(err) {
      if (err) {
        console.log(err);
        return next(err);
      } else {
        return message.save(function(err) {
          if (err) {
            console.log(err);
            return next(err);
          } else {
            return res.send(message);
          }
        });
      }
    });
  } else {
    console.log('hi2');
    return message.save(function(err) {
      if (err) {
        console.log(err);
        return next(err);
      } else {
        return res.send(message);
      }
    });
  }
};

exports.incomingListener = function(req, res, next) {
  var messageContent;
  messageContent = req.body.Body;
  return Question.find().exec(function(err, questions) {
    var counter, done;
    if (err) {
      return console.log('oh no!');
    } else {
      done = false;
      counter = questions.length;
      if (counter === 0) {
        done = true;
        AddMessageToDB(messageContent, req, res);
      }
      return questions.forEach(function(question, index, questions) {
        var text1, text2, url;
        if (!done) {
          url = "http://www.tools4noobs.com/ajax_string_similarity?text=";
          text1 = encodeURI(messageContent);
          text2 = encodeURI(question);
          url = url + text1 + '&text2=' + text2 + '&limit=0.0';
          return http.get(url, function(resp) {
            var responseText;
            responseText = "";
            resp.on('data', function(chunk) {
              return responseText += chunk;
            });
            return resp.on('end', function() {
              var accountSid, authtoken, client, confidence, destination, similarity, source;
              if (!done) {
                confidence = (responseText.match(/\d+\.\d+/g))[0];
                similarity = parseFloat(confidence);
                console.log(similarity);
                if (similarity > 30.0) {
                  if (question.answer !== "") {
                    console.log('need to send answer as:' + question.answer);
                    destination = req.body.From;
                    source = req.body.To;
                    accountSid = "ACfaa9a45e4f94940cee4d879837d92761";
                    authtoken = "330fc8bcc245be6475447062f80bc899";
                    client = new twilio.RestClient(accountSid, authtoken);
                    client.sms.messages.create({
                      to: destination,
                      from: source,
                      body: question.answer
                    }, function(err, message) {
                      if (!err) {
                        return console.log(message.sid);
                      } else {
                        return console.log('OOPS!');
                      }
                    });
                  } else {
                    AddMessageToDB(messageContent, req, res, question._id);
                  }
                  done = true;
                  res.send('Success');
                  return;
                } else {
                  counter -= 1;
                }
                if (counter === 0) {
                  done = true;
                  return AddMessageToDB(messageContent, req, res);
                }
              }
            });
          });
        }
      });
    }
  });
};

exports.all = function(req, res, next) {
  var lastAccessedTime;
  lastAccessedTime = new Date(req.params.lastAccessedTime);
  return Message.find().exec(function(err, messages) {
    var output;
    if (err) {
      return next(err);
    } else {
      output = {
        messages: messages
      };
      return res.send(output);
    }
  });
};

exports.insert = function(req, res, next) {
  var message, questionObj;
  questionObj = new Question({
    question: req.body.question.question,
    answer: req.body.question.answer
  });
  message = new Message({
    source: req.body.source,
    destination: req.body.destination,
    question: questionObj._id,
    time: Date.now()
  });
  return questionObj.save(function(err) {
    if (err) {
      return next(req);
    } else {
      return message.save(function(err) {
        if (err) {
          return next(err);
        } else {
          return res.send(message);
        }
      });
    }
  });
};
