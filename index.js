#!/usr/bin/env node

const { join } = require('path');
const inquirer = require('inquirer');
const execa = require('execa');
const TMP_DIR = require('temp-dir');

const WARNING_SPACER = '    ';

const requiredConfig = [
  {
    type: 'input',
    name: 'TWILIO_ACCOUNT_SID',
    message: 'Your account SID:'
  },
  {
    type: 'password',
    name: 'TWILIO_AUTH_TOKEN',
    message: 'Your auth token:'
  },
  {
    type: 'input',
    name: 'MY_PHONE_NUMBER',
    message: 'Your phone number:'
  }
];

const logWarning = msg => console.log(`\n⚠️   ${msg}`);

const entryNeedsConsoleHint = entry => {
  const requiredEntries = ['TWILIO_ACCOUNT_SID', 'TWILIO_AUTH_TOKEN'];

  return requiredEntries.includes(entry.name);
};
const configNeedsConsoleHint = config =>
  !!config.filter(entry => entryNeedsConsoleHint(entry)).length;

async function getConfigData() {
  const { config, inquirerConfig } = requiredConfig.reduce(
    (acc, cur) => {
      const { name } = cur;
      const { config, inquirerConfig } = acc;

      if (process.env[name]) {
        console.log(
          `Using detected env variable: ${name}=${process.env[name].substr(
            0,
            8
          )}...`
        );
        config[name] = process.env[name];
      } else {
        inquirerConfig.push(cur);
      }
      return acc;
    },
    { config: {}, inquirerConfig: [] }
  );

  if (configNeedsConsoleHint(inquirerConfig)) {
    logWarning(
      'To authenticate with Twilio make sure you have access to your Twilio console (twilio.com/console)'
    );
    console.log(
      `${WARNING_SPACER}There you'll find your Account SID and your Auth Token.\n`
    );
  }

  return { TMP_DIR, ...config, ...(await inquirer.prompt(inquirerConfig)) };
}

async function warnAboutCost() {
  logWarning("By running this script you'll be buying a Twilio phone Number.");
  console.log(
    `${WARNING_SPACER}Have a look at https://www.twilio.com/pricing to learn more.\n`
  );

  const { awareOfCost } = await inquirer.prompt({
    type: 'list',
    choices: ['Yes', 'Oh no!'],
    message: 'Do you want to proceed?',
    name: 'awareOfCost'
  });

  if (awareOfCost !== 'Yes') {
    throw new Error('Cancelling to avoid cost');
  }
}

(async () => {
  try {
    await warnAboutCost();

    let config = await getConfigData();

    const childProcess = execa(
      join(__dirname, 'bin', 'create-phone-number-forwarding.sh'),
      {
        env: config
      }
    );

    childProcess.stdout.pipe(process.stdout);
    childProcess.stderr.pipe(process.stderr);

    await childProcess;

    console.log('🎉  All done.');
  } catch (error) {
    console.error(error);
    // we only need to cancel because logs are piped to stderr anyways
    process.exit(1);
  }
})();
