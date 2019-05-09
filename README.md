# Mail for Containers

Use in a docker compose environment to centralize email relaying to a smart host

## Environment variables:

POSTFIX\_HOSTNAME      - name of this postfix host
                        must not be empty
POSTFIX\_RELAYHOST     - name of the relay host with optional port
                        relay.example.com[:587]
                        must not be empty if AUTH credentials provided
POSTFIX\_AUTH\_USERNAME - user name to authenticate with POSTFIX\_RELAYHOST
POSTFIX\_AUTH\_PASSWORD - password for POSTFIX\_AUTH\_USERNAME
SES\_AUTH\_USERNAME     - alternate to POSTFIX\_AUTH\_USERNAME
SES\_AUTH\_PASSWORD     - alternate to POSTFIX\_AUTH\_PASSWORD


If the SES AUTH alternates are used, the POSTFIX\_RELAYHOST is checked to ensure
it is an SES relay host, and if the port spec is omitted, then port 587 is added.

## Logging

Postfix logs to the file /var/log/maillog

## Running Locally

The container can be tested by running it locally

    make
    docker run -p2525:25 \
        -e POSTFIX_HOSTNAME=smtp.cogosense.com \
        -e POSTFIX_RELAYHOST=email-smtp.us-west-2.amazonaws.com:587 \
        -e POSTFIX_AUTH_USERNAME=<USERNAME> \
        -e POSTFIX_AUTH_PASSWORD="<PASSWORD>" \
        -v $PWD/log:/var/log \
        -v $PWD/spool:/var/spool \
        --rm \
        053262612181.dkr.ecr.us-west-2.amazonaws.com/postfix:dev

Different regions can be tested by changing the region name is the SES relayhost name.

* email-smtp.us-west-2.amazonaws.com
* email-smtp.us-east-1.amazonaws.com
* email-smtp.eu-west-1.amazonaws.com

Send an email using telnet (server responses are omitted):

    telnet 0.0.0.0 2525
    EHLO cogosense.com
    MAIL FROM: <from@example.com>
    RCPT TO: <to@another_domain.com>
    DATA
    Subject: Test Again

    This is another test
    .
    quit

## Docker Compose

An example docker-compose.yml

    services:
        smtp:
            image: <registry>/postfix
            volumes:
                - ./log:/var/log
                - ./spool:/var/spool
            environment:
                POSTFIX_HOSTNAME: mailhost
                POSTFIX_RELAYHOST: mailrelay.example.com:587
                POSTFIX_AUTH_USERNAME: jimmy
                POSTFIX_AUTH_PASSWORD: shushverysecret
        app:
            image: <registry>/app
            depends_on:
                - smtp
