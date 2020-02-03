#!/usr/bin/env node

const inquirer = require('inquirer');
const execa = require('execa');
const TMP_DIR = require('temp-dir');

async function getConfigData() {
  const {
    MY_PHONE_NUMBER,
    TWILIO_ACCOUNT_SID,
    TWILIO_AUTH_TOKEN
  } = process.env;

  const config = {
    MY_PHONE_NUMBER,
    TMP_DIR,
    TWILIO_ACCOUNT_SID,
    TWILIO_AUTH_TOKEN
  };

  if (MY_PHONE_NUMBER && TWILIO_ACCOUNT_SID && TWILIO_AUTH_TOKEN) {
    return config;
  }

  console.log(
    '⚠️  Before we get started make sure you have access to your Twilio console (twilio.com/console)'
  );
  console.log("   There you'll find your Account SID and your Auth Token.");

  const promptItems = [];

  if (!TWILIO_ACCOUNT_SID) {
    promptItems.push({
      type: 'input',
      name: 'TWILIO_ACCOUNT_SID',
      message: 'Your account SID:'
    });
  }

  if (!TWILIO_AUTH_TOKEN) {
    promptItems.push({
      type: 'password',
      name: 'TWILIO_AUTH_TOKEN',
      message: 'Your auth token:'
    });
  }

  if (!MY_PHONE_NUMBER) {
    promptItems.push({
      type: 'input',
      name: 'MY_PHONE_NUMBER',
      message: 'Your phone number:'
    });
  }

  return { ...config, ...(await inquirer.prompt(promptItems)) };
}

(async () => {
  try {
    let config = await getConfigData();

    const childProcess = execa('./bin/create-phone-number-forwarding.sh', {
      env: config
    });
    childProcess.stdout.pipe(process.stdout);
    childProcess.stderr.pipe(process.stderr);

    await childProcess;

    console.log('✅  All done');
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
})();
