#!/bin/sh

sudo -u petals rm -f /var/log/petals-registry/petals-registry-overlay.log.0
sudo -u petals petals-registry -c file:///etc/petals-registry/member-available/${memberId}/member.properties &

ret="1"
try=0
while [ $ret -ne 0 -a $try -le 30 ]
do
 sleep 1
 cat /var/log/petals-registry/petals-registry-overlay.log.0 | grep "Petals Registry Overlay local member started"
 ret=$?
 try=`expr $try + 1` 
done

exit $ret
