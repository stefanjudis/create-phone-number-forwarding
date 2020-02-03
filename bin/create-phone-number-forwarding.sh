#!/bin/bash

# DISCLAIMER I'M ALL UP FOR IMPROVEMENTS OF THIS SHELL SCRIPT
# ℹ️ If you have comments please file an issue
#     https://github.com/stefanjudis/create-phone-number-forwarding/issues

# extend path to access jq and the Twilio CLI
export PATH="$PATH:$PWD/node_modules/.bin"

echo "💻  Running 'create-phone-number-forwarding.sh'"

# ℹ️ WAITING FOR FEEDBACK
# If enough people want it we can extend this with a flexible country code
TWILIO_NUMBER_COUNTRY=US
TMP_SERVICE_DIR=$TMP_DIR/twilio-number-forwarding

########################################
# STEP 1: CREATE FILES FOR SERVERLESS SERVICE
echo "Creating tmp directory for serverless service at"
echo $TMP_SERVICE_DIR

# in case you run it several times and the same tmp dir exist
# copy over it
if [[ -d "$TMP_SERVICE_DIR" ]]
then
  rm -rf $TMP_SERVICE_DIR
fi

cp -r ./service-template $TMP_SERVICE_DIR
printf "AUTH_TOKEN=$TWILIO_AUTH_TOKEN\nACCOUNT_SID=$TWILIO_ACCOUNT_SID\nMY_PHONE_NUMBER=$MY_PHONE_NUMBER" > $TMP_SERVICE_DIR/.env

########################################
# STEP 2: DEPLOY SERVERLESS SERVICE
echo "Deploying tmp service files using twilio-run"
DEPLOY_OUTPUT=$(cd $TMP_SERVICE_DIR; pwd; twilio-run deploy)

# ℹ️ If you know a nicer way to grep the URL please let me know
VOICE_ENDPOINT_URL=$(echo $DEPLOY_OUTPUT | grep -o "/forward-call https://.*twil.io/forward-call" | grep -o "https://.*twil.io/forward-call")
SMS_ENDPOINT_URL=$(echo $DEPLOY_OUTPUT | grep -o "/forward-message https://.*twil.io/forward-message" | grep -o "https://.*twil.io/forward-message")

echo "Deployed Twilio Functions..."
echo $VOICE_ENDPOINT_URL
echo $SMS_ENDPOINT_URL

########################################
# STEP 3: BUY A NEW TWILIO PHONE NUMBER
echo "Buying phone number"
TWILIO_NUMBER=$(twilio api:core:available-phone-numbers:local:list --country-code $TWILIO_NUMBER_COUNTRY --sms-enabled --voice-enabled -o json | jq -r '.[0] | .phoneNumber')
twilio api:core:incoming-phone-numbers:local:create --phone-number="$TWILIO_NUMBER" -o json | jq -r '.[0] | .friendlyName'
echo "Bought number: $TWILIO_NUMBER"

########################################
# STEP 4: CONFIGURE PHONE NUMBER
echo "Configuring phone number"
twilio phone-numbers:update $TWILIO_NUMBER  --sms-url=$SMS_ENDPOINT_URL --voice-url=$VOICE_ENDPOINT_URL
echo "Updated phone number"

########################################
# STEP 5: CELEBRATE SUCCESS
echo '✅  `create-phone-number-forwarding.sh` finished successfully'
echo "Calls and message to $TWILIO_NUMBER will now be forwarded to $MY_PHONE_NUMBER"