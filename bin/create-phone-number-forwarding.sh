#!/bin/bash

# DISCLAIMER I'M ALL UP FOR IMPROVEMENTS OF THIS SHELL SCRIPT
# ℹ️ If you have comments please file an issue
#     https://github.com/stefanjudis/create-phone-number-forwarding/issues

echo "💻  Running 'create-phone-number-forwarding.sh'"

################################################################################
# STEP 1: VARIABLE SETUP

# Get directory of this script, copied from on SO
# https://stackoverflow.com/questions/59895/how-to-get-the-source-directory-of-a-bash-script-from-within-the-script-itself
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# extend path to access jq, twilio-run, the Twilio CLI, ...
export PATH="$PATH:$CURRENT_DIR/../node_modules/.bin"

# ! WAITING FOR FEEDBACK
# If enough people want it we can extend this with a flexible country code
TWILIO_NUMBER_COUNTRY=US

# TEMPORARY DIRECTORY THAT WILL BE DEPLOYED TO TWILIO FUNCTIONS
TMP_SERVICE_DIR=$TMP_DIR/twilio-number-forwarding

################################################################################
# STEP 2: CREATE FILES FOR SERVERLESS SERVICE
echo "Creating tmp directory for serverless service at"
echo $TMP_SERVICE_DIR

# in case you run it several times and the same tmp dir exist
# remove it before you move on
if [[ -d "$TMP_SERVICE_DIR" ]]
then
  rm -rf $TMP_SERVICE_DIR
fi

cp -r $CURRENT_DIR/../service-template $TMP_SERVICE_DIR
printf "AUTH_TOKEN=$TWILIO_AUTH_TOKEN\nACCOUNT_SID=$TWILIO_ACCOUNT_SID\nMY_PHONE_NUMBER=$MY_PHONE_NUMBER" > $TMP_SERVICE_DIR/.env

################################################################################
# STEP 3: DEPLOY SERVERLESS SERVICE
echo "Deploying tmp service files using twilio-run"
DEPLOY_OUTPUT=$(cd $TMP_SERVICE_DIR; twilio-run deploy)

# ℹ️ If you know a nicer way to grep the URL please let me know
VOICE_ENDPOINT_URL=$(echo $DEPLOY_OUTPUT | grep -o "/forward-call https://.*twil.io/forward-call" | grep -o "https://.*twil.io/forward-call")
SMS_ENDPOINT_URL=$(echo $DEPLOY_OUTPUT | grep -o "/forward-message https://.*twil.io/forward-message" | grep -o "https://.*twil.io/forward-message")

echo "Deployed Twilio Functions..."
echo $VOICE_ENDPOINT_URL
echo $SMS_ENDPOINT_URL

################################################################################
# STEP 4: BUY A NEW TWILIO PHONE NUMBER
echo "Buying phone number"
TWILIO_NUMBER=$(twilio api:core:available-phone-numbers:local:list --country-code $TWILIO_NUMBER_COUNTRY --sms-enabled --voice-enabled -o json | jq -r '.[0] | .phoneNumber')
twilio api:core:incoming-phone-numbers:local:create --phone-number="$TWILIO_NUMBER" -o json | jq -r '.[0] | .friendlyName'
echo "Bought number: $TWILIO_NUMBER"

################################################################################
# STEP 5: CONFIGURE PHONE NUMBER
echo "Configuring phone number"
twilio phone-numbers:update $TWILIO_NUMBER  --sms-url=$SMS_ENDPOINT_URL --voice-url=$VOICE_ENDPOINT_URL
echo "Updated phone number"

################################################################################
# STEP 6: CELEBRATE SUCCESS
echo '✅  `create-phone-number-forwarding.sh` finished successfully'
echo "Calls and message to $TWILIO_NUMBER will now be forwarded to $MY_PHONE_NUMBER"