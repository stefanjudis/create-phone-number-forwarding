#!/bin/bash
#
# DISCLAIMER I'M ALL UP FOR IMPROVEMENTS OF THIS SHELL SCRIPT
# If you have comments please file an issue
# https://github.com/stefanjudis/create-phone-number-forwarding/issues
#
# Script Name: create-phone-number-forwarding.sh
#
# Author: Stefan Judis
#
# Description: Buys a Twilio number and configures it to forward all calls and
# messages to $MY_PHONE_NUMBER. This is done via serverless functions which are
# also created by running this script
#

# fail script after any non-0 status code
# More info: https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -e

function log_step()
{
  echo ""
  echo "💻  $1"
  if [ ! -z "$2" ]; then
    echo "    -> $2"
  fi
}

function log_info()
{
  echo "ℹ️   $1"
}

function get_service_sid()
{
    EXISTING_SERVICE_SID=$(twilio api:serverless:v1:services:list -o json | jq -r ".[] | select(.friendlyName == \"$SERVICE_NAME\") | .sid")
}

function get_service_domain()
{
  local SERVICE_DOMAIN_WITHOUT_PROTOCOL=$(twilio api:serverless:v1:services:environments:list --service-sid $EXISTING_SERVICE_SID -o json | jq -r '.[] | select(.uniqueName == "dev-environment") | .domainName')
  SERVICE_DOMAIN="https://$SERVICE_DOMAIN_WITHOUT_PROTOCOL"
}

function create_service_and_get_domain()
{
  log_step "Creating tmp directory for serverless service at" $TMP_SERVICE_DIR

  # in case you run it several times and the same tmp dir exist
  # remove it before you move on
  if [[ -d "$TMP_SERVICE_DIR" ]]
  then
    rm -rf $TMP_SERVICE_DIR
  fi

  cp -r $CURRENT_DIR/../service-template $TMP_SERVICE_DIR
  printf "AUTH_TOKEN=$TWILIO_AUTH_TOKEN\nACCOUNT_SID=$TWILIO_ACCOUNT_SID\nMY_PHONE_NUMBER=$MY_PHONE_NUMBER" > $TMP_SERVICE_DIR/.env

  log_step "Deploying new service files using twilio-run..."

  DEPLOY_OUTPUT=$(cd $TMP_SERVICE_DIR; twilio-run deploy --service-name=$SERVICE_NAME)
  SERVICE_DOMAIN=$(echo $DEPLOY_OUTPUT | grep -o "https://$SERVICE_NAME.*.dev.twil.io" | grep -o " https://$SERVICE_NAME.*.dev.twil.io")
}


# Get directory of this script, copied from on SO
# https://stackoverflow.com/questions/59895/how-to-get-the-source-directory-of-a-bash-script-from-within-the-script-itself
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# extend path to access jq, twilio-run, the Twilio CLI, ...
export PATH="$CURRENT_DIR/../node_modules/.bin:$CURRENT_DIR/../node_modules/node-jq/bin:$PATH"

# ##############################################################################
# --- START OF THE SCRIPT ######################################################
# ##############################################################################

log_step "Running bash script" "$CURRENT_DIR/create-phone-number-forwarding.sh"

# ! WAITING FOR FEEDBACK
# If enough people want it we can extend this with a flexible country code
# https://github.com/stefanjudis/create-phone-number-forwarding/issues/1
TWILIO_NUMBER_COUNTRY=US

# TEMPORARY DIRECTORY THAT WILL BE DEPLOYED TO TWILIO FUNCTIONS
TMP_SERVICE_DIR=$TMP_DIR/twilio-number-forwarding

# THE NAME OF THE DEPLOYED SERVERLESS SERVICE
# IT'S ACCESSIBLE HERE -> https://www.twilio.com/console/functions/api
SERVICE_NAME="forward-to-${MY_PHONE_NUMBER//+}"


# --- GET EXISTING SERVICE SID #################################################

# THIS VARIABLE WILL BE SET BY get_service_sid
EXISTING_SERVICE_SID=""
get_service_sid
log_info "EXISTING_SERVICE_SID: $EXISTING_SERVICE_SID"


# --- GET/CREATE SERVERLESS DOMAIN #############################################

# THIS VARIABLE WILL BE SET BY
# get_service_domain or create_service_and_get_domain
SERVICE_DOMAIN=""

if [[ $EXISTING_SERVICE_SID ]]
then
  log_step "Found an existing service forwarding to your number. Getting it's domain..."
  get_service_domain
else
  log_step "No existing serverless service found. Creating a new one..."
  create_service_and_get_domain
fi

log_info "SERVICE_DOMAIN: $SERVICE_DOMAIN"

VOICE_ENDPOINT_URL="$SERVICE_DOMAIN/forward-call"
SMS_ENDPOINT_URL="$SERVICE_DOMAIN/forward-message"

log_info "Protected serverless functions deployed"
log_info "To learn more about signature validation: https://www.twilio.com/docs/runtime/functions/request-flow"

# --- BUY A PHONE NUMBER #######################################################

log_step "Querying and buying a phone number..."
TWILIO_NUMBER=$(twilio api:core:available-phone-numbers:local:list --country-code $TWILIO_NUMBER_COUNTRY --sms-enabled --voice-enabled -o json | jq -r '.[0] | .phoneNumber')
log_info "Found number: $TWILIO_NUMBER"
twilio api:core:incoming-phone-numbers:local:create --phone-number="$TWILIO_NUMBER" -o json | jq -r '.[0] | .friendlyName'
log_info "Bought number: $TWILIO_NUMBER"


# --- CONFIGURE PHONE NUMBER ###################################################

log_step "Configuring phone number with functions"
twilio phone-numbers:update $TWILIO_NUMBER  --sms-url $SMS_ENDPOINT_URL --voice-url $VOICE_ENDPOINT_URL
log_info "Updated phone number"
log_info "See number configurat at https://www.twilio.com/console/phone-numbers/incoming"


# --- CELEBRATE ################################################################

log_step "Script finished successfully" "Calls and messages to $TWILIO_NUMBER will now be forwarded to $MY_PHONE_NUMBER"
