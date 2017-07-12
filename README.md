# Logger for Containers

Use in a docker compose environment to centralize email relaying to smart host

An example docker-compose.yml

    volumes:
        dev:
    services:
        logger:
            image <registry>/postfix
            volumes:
                - ./var/log:/var/log
        app:
            image: <registry>/app
            volumes:
                - dev:/dev

