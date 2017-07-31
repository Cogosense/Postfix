# Mail for Containers

Use in a docker compose environment to centralize email relaying to a smart host

Use in conjunction with [Logger](//github.com/Cogosense/Logger) for centralized logging

An example docker-compose.yml

    volumes:
        dev:
    services:
        logger:
            image: <registry>/logger
            volumes:
                - dev:/dev
                - ./var/log:/var/log
        smtp:
            image: <registry>/postfix
            volumes:
                - dev:/dev/logger
            environment:
                POSTFIX_HOSTNAME: $POSTFIX_HOSTNAME
                POSTFIX_RELAYHOST: $POSTFIX_RELAYHOST
                POSTFIX_AUTH_USERNAME: $POSTFIX_AUTH_USERNAME
                POSTFIX_AUTH_PASSWORD: $POSTFIX_AUTH_PASSWORD
            depends_on:
                - logger
        app:
            image: <registry>/app
            depends_on:
                - smtp

*POSTFIX\_AUTH\_USERNAME* and *POSTFIX\_AUTH\_PASSWORD* are optional and onlt required if the
SMTP relay host requires SASL auth.

If using logger, the following link must be created at runtime:

    if [ -d /dev/logger ] ; then
        ln -sf /dev/logger/log /dev/log
    fi
