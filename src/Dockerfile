FROM alpine:3.12
MAINTAINER Steve Williams <swilliams@cogosense.com>

# install dev tools
RUN apk --update add --no-cache tini postfix cyrus-sasl-plain cyrus-sasl-login ca-certificates

WORKDIR /var/run/postfix
COPY . .

EXPOSE 25
VOLUME ["/var/sppol/postfix"]
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["./postfix.sh"]

