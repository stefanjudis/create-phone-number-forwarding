exports.handler = function(context, event, callback) {
  const { MY_PHONE_NUMBER } = context;

  let twiml = new Twilio.twiml.MessagingResponse();
  if (event.From === MY_PHONE_NUMBER) {
    const separatorPosition = event.Body.indexOf(':');
    if (separatorPosition < 1) {
      twiml.message(
        'You need to specify a recipient number and a ":" before the message.'
      );
    } else {
      const recipientNumber = event.Body.substr(0, separatorPosition).trim();
      const messageBody = event.Body.substr(separatorPosition + 1).trim();
      twiml.message({ to: recipientNumber }, messageBody);
    }
  } else {
    twiml.message({ to: MY_PHONE_NUMBER }, `${event.From}: ${event.Body}`);
  }
  callback(null, twiml);
};
