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
            depends_on:
                - logger
        app:
            image: <registry>/app
            depends_on:
                - smtp

If using logger, the following link must be created at runtime:

    if [ -d /dev/logger ] ; then
        ln -sf /dev/logger/log /dev/log
    fi
