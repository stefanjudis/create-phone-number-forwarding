exports.handler = function(context, event, callback) {
  let twiml = new Twilio.twiml.MessagingResponse();
  twiml.message(`From: ${event.From}. Message: ${event.Body}`, {
    to: context.MY_PHONE_NUMBER
  });
  callback(null, twiml);
};
