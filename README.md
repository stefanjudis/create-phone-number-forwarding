![Logo showing a masked man with a hat](./logo.jpg)

---

# create-phone-number-forwarding (`CPNF`)

> A small CLI utility that buys a Twilio number and forwards incoming calls/SMS' to your own number

### Prerequisite

To buy and configure phone numbers using `CPNF` you need to have **[a free Twilio account](http://twilio.com/try-twilio)** and **a UNIX'y environment**.

### Okay, but what's Twilio?

Twilio is a global cloud communications and customer engagement platform that has several APIs at it's core. These APIs enable developers to build and automate flows that usually happen over phone, SMS, Whatsapp, Email, ...

## Setup

Make sure you have the following configuration values at hand (or stored in environment variables):

- your Twilio account SID (`TWILIO_ACCOUNT_SID`)
- your Twilio auth token (`TWILIO_AUTH_TOKEN`)
- the phone number you want redirect calls and SMS to (`MY_PHONE_NUMBER`)

`CPNF` will ask for these values if they were not present in the environment variables.

```
npx run create-phone-number-forwarding

# or alternatively
npm i -g create-phone-number-forwarding
create-phone-number-forwarding
```

That's it to buy and configure a phone number. 👆

## Cool, but how does this work?

`CPNF` sits on top of [twilio-run](https://github.com/twilio-labs/twilio-run) and [the Twilio CLI](https://www.twilio.com/docs/twilio-cli/quickstart). All the logic and functionality can be found in [create-phone-number-forwarding.sh](https://github.com/stefanjudis/create-phone-number-forwarding/blob/master/bin/create-phone-number-forwarding.sh).

![Diagram showing the flow of the proxy number](./diagram.png)
