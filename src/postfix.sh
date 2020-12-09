#!/bin/sh -x
POSTFIX_RUNDIR=/var/spool/postfix
[ -n "$POSTFIX_HOSTNAME" ] || { echo "set POSTFIX_HOSTNAME parameter in .env file" ; exit 1; }
if [ -n "$SES_AUTH_USERNAME" ] ; then
    [ -n "$SES_AUTH_PASSWORD" ] || { echo "set POSTFIX_AUTH_PASSWORD parameter in .env file" ; exit 1; }
    [ -n "$POSTFIX_RELAYHOST" ] || { echo "set POSTFIX_RELAYHOST parameter in .env file" ; exit 1; }
    case $POSTFIX_RELAYHOST in
        email-smtp.*.amazonaws.com) POSTFIX_RELAYHOST=$POSTFIX_RELAYHOST:587;;
        email-smtp.*.amazonaws.com:*) ;;
        *) echo "POSTFIX_RELAYHOST is not an SES relay host" ; exit 1;;
    esac
    POSTFIX_AUTH_USERNAME="$SES_AUTH_USERNAME"
    POSTFIX_AUTH_PASSWORD="$SES_AUTH_PASSWORD"
else
    if [ -n "$POSTFIX_AUTH_USERNAME" ] ; then
        [ -n "$POSTFIX_AUTH_PASSWORD" ] || { echo "set POSTFIX_AUTH_PASSWORD parameter in .env file" ; exit 1; }
        [ -n "$POSTFIX_RELAYHOST" ] || { echo "set POSTFIX_RELAYHOST parameter in .env file" ; exit 1; }
    fi
fi

case $POSTFIX_RELAYHOST in
    '') ;;
    *:*)
        hostpart=${POSTFIX_RELAYHOST%%:*}
        portpart=${POSTFIX_RELAYHOST#*:}
        POSTFIX_RELAYHOST="[$hostpart]"${portpart:+":$portpart"}
        ;;
    *)
        POSTFIX_RELAYHOST="[$POSTFIX_RELAYHOST]"
        ;;
esac

chown root /var/spool/postfix
chown root /var/spool/postfix/pid

touch /etc/aliases

ipaddr=`hostname -i`
eval `ipcalc -n $ipaddr`
eval `ipcalc -p $ipaddr`
MYNETWORK=$NETWORK/$PREFIX

#
# rate limit
#
/usr/sbin/postconf smtp_destination_concurrency_limit=2
/usr/sbin/postconf smtp_destination_rate_delay=1s
/usr/sbin/postconf smtp_extra_recipient_limit=10

#
# log to file
#
/usr/sbin/postconf maillog_file=/var/log/maillog

/usr/sbin/postconf smtputf8_enable=no
/usr/sbin/postconf myhostname=$POSTFIX_HOSTNAME
/usr/sbin/postconf mynetworks=$MYNETWORK
/usr/sbin/postconf alias_database=/etc/aliases
/usr/sbin/postconf alias_maps=hash:/etc/aliases
newaliases

if [ -n "$POSTFIX_RELAYHOST" ] ; then
    /usr/sbin/postconf relayhost="$POSTFIX_RELAYHOST"
    if [ -n "$POSTFIX_AUTH_USERNAME" ] ; then
        /usr/sbin/postconf smtp_sasl_auth_enable=yes
        /usr/sbin/postconf smtp_sasl_security_options=noanonymous
        /usr/sbin/postconf smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd
        /usr/sbin/postconf smtp_use_tls=yes
        /usr/sbin/postconf smtp_tls_security_level=encrypt
        /usr/sbin/postconf smtp_tls_note_starttls_offer=yes
        /usr/sbin/postconf smtp_tls_CAfile=/etc/ssl/certs/ca-certificates.crt
        echo "$POSTFIX_RELAYHOST $POSTFIX_AUTH_USERNAME:$POSTFIX_AUTH_PASSWORD" > /etc/postfix/sasl_passwd
    fi
fi

if [ -f /etc/postfix/sasl_passwd ] ; then
        /usr/sbin/postmap /etc/postfix/sasl_passwd
        chown root:root /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
        chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
fi

/usr/sbin/postfix start-fg
