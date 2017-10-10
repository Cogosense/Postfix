FROM alpine
MAINTAINER Steve Williams <swilliams@cogosense.com>

ENV TINI_SHA 066ad710107dc7ee05d3aa6e4974f01dc98f3888

# install dev tools
RUN apk --update add --no-cache stunnel postfix ca-certificates \
    && apk add --virtual=build-deps curl openssl \
    && openssl req \
            -new \
            -out /etc/stunnel/mail.pem \
            -keyout /etc/stunnel/mail.pem \
            -nodes \
            -x509 \
            -days 365 \
            -subj "/C=CA/ST=British Columbia/L=Port Moody/O=Cogosense Technology Inc./CN=mailhost" \
    && curl -fsSL https://github.com/krallin/tini/releases/download/v0.5.0/tini-static -o /bin/tini && chmod +x /bin/tini \
    && echo "$TINI_SHA  /bin/tini" | sha1sum -c - \
    && apk del build-deps

WORKDIR /var/spool/postfix
COPY . .
RUN chown stunnel /etc/stunnel/mail.pem \
    && chmod 400 /etc/stunnel/mail.pem \
    && mkdir /var/log/stunnel \
    && chown stunnel /var/log/stunnel \
    && mkdir /run/stunnel \
    && chown stunnel /run/stunnel \
    && cat stunnel.conf >> /etc/stunnel/stunnel.conf && rm stunnel.conf

EXPOSE 25
VOLUME ["/var/log", "/var/sppol/postfix"]
ENTRYPOINT ["/bin/tini", "--"]
CMD ["sh", "-x", "postfix.sh"]

