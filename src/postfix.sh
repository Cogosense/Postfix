#!/bin/sh -x
POSTFIX_RUNDIR=/var/spool/postfix
[ -n "$POSTFIX_HOSTNAME" ] || { echo "set POSTFIX_HOSTNAME parameter in .env file" ; exit 1; }
if [ -n "$SES_AUTH_USERNAME" ] ; then
    [ -n "$SES_AUTH_PASSWORD" ] || { echo "set POSTFIX_AUTH_PASSWORD parameter in .env file" ; exit 1; }
    POSTFIX_RELAYHOST='127.0.0.1:2525'
else
    if [ -n "$POSTFIX_AUTH_USERNAME" ] ; then
        [ -n "$POSTFIX_AUTH_PASSWORD" ] || { echo "set POSTFIX_AUTH_PASSWORD parameter in .env file" ; exit 1; }
        [ -n "$POSTFIX_RELAYHOST" ] || { echo "set POSTFIX_RELAYHOST parameter in .env file" ; exit 1; }
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
fi

if [ -d /dev/logger ] ; then
    ln -sf /dev/logger/log /dev/log
fi

#
# start stunnel = stunnel daemonizes
#
stunnel /etc/stunnel/stunnel.conf

chown root /var/spool/postfix
chown root /var/spool/postfix/pid

touch /etc/aliases

ipaddr=`hostname -i`
eval `ipcalc -n $ipaddr`
eval `ipcalc -p $ipaddr`
MYNETWORK=$NETWORK/$PREFIX

/usr/sbin/postconf smtputf8_enable=no
/usr/sbin/postconf myhostname=$POSTFIX_HOSTNAME
/usr/sbin/postconf mynetworks=$MYNETWORK
/usr/sbin/postconf alias_database=/etc/aliases
/usr/sbin/postconf alias_maps=hash:/etc/aliases
newaliases

if [ -n "$POSTFIX_RELAYHOST" ] ; then
    /usr/sbin/postconf relayhost="$POSTFIX_RELAYHOST"
fi

if [ -n "$SES_AUTH_USERNAME" ] ; then
    #
    # setup relaying via AWS SES over stunnel
    #
    echo "$POSTFIX_RELAYHOST $SES_AUTH_USERNAME:$SES_AUTH_PASSWORD" > /etc/postfix/sasl_passwd
    /usr/sbin/postconf smtp_sasl_auth_enable=yes
    /usr/sbin/postconf smtp_sasl_security_options=noanonymous
    /usr/sbin/postconf smtp_tls_security_level=may
    /usr/sbin/postconf smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd
elif [ -n "$POSTFIX_AUTH_USERNAME" ] ; then
    echo "$POSTFIX_RELAYHOST $POSTFIX_AUTH_USERNAME:$POSTFIX_AUTH_PASSWORD" > /etc/postfix/sasl_passwd
    /usr/sbin/postmap /etc/postfix/sasl_passwd
    chown root:root /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
    chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
    /usr/sbin/postconf smtp_sasl_auth_enable=yes
    /usr/sbin/postconf smtp_sasl_security_options=noanonymous
    /usr/sbin/postconf smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd
    /usr/sbin/postconf smtp_use_tls=yes
    /usr/sbin/postconf smtp_tls_CAfile=/etc/ssl/certs/ca-certificates.crt
fi

if [ -f /etc/postfix/sasl_passwd ] ; then
        /usr/sbin/postmap /etc/postfix/sasl_passwd
        chown root:root /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
        chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
fi

rm -f $POSTFIX_RUNDIR/pid/master.pid
/usr/sbin/postfix start
if [ -f $POSTFIX_RUNDIR/pid/master.pid ] ; then
    pid=`expr $(cat $POSTFIX_RUNDIR/pid/master.pid)`

    if ! kill -0 $pid ; then
        echo "postfix failed to start"
        exit 1
    fi
    tail -f /proc/$pid/cmdline 2>&1 | while read line ; do
        case "$line" in
            *No\ such\ process)
                echo "postfix exited"
                break
                ;;
        esac
    done
fi
