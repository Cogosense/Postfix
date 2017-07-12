#!/bin/sh
POSTFIX_RUNDIR=/var/spool/postfix
[ -n "$POSTFIX_HOSTNAME" ] || { echo "set POSTFIX_HOSTNAME parameter in .env file" ; exit 1; }
[ -n "$POSTFIX_RELAYHOST" ] || { echo "set POSTFIX_RELAYHOST parameter in .env file" ; exit 1; }

if [ -d /dev/logger ] ; then
    ln -sf /dev/logger/log /dev/log
fi

chown root /var/spool/postfix
chown root /var/spool/postfix/pid

touch /etc/aliases

ipaddr=`hostname -i`
eval `ipcalc -n $ipaddr`
eval `ipcalc -p $ipaddr`
MYNETWORK=$NETWORK/$PREFIX

/usr/sbin/postconf smtputf8_enable=no
/usr/sbin/postconf myhostname=$POSTFIX_HOSTNAME
/usr/sbin/postconf relayhost="[$POSTFIX_RELAYHOST]"
/usr/sbin/postconf mynetworks=$MYNETWORK
/usr/sbin/postconf alias_database=/etc/aliases
/usr/sbin/postconf alias_maps=hash:/etc/aliases

newaliases

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
