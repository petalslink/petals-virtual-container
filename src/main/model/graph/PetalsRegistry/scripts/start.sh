#!/bin/sh

#
# Generate the basic configuration of the Petals Registry
# ----------------
# The basic configuration is a cluster composed of only member. Other members will be added dynamically through the script 'update.sh'
# that will register other members to the current one
#
./generate-cluster-cfg.sh
./generate-member-properties.sh
./generate-logging-properties.sh

sudo -u petals rm -f /var/log/petals-registry/petals-registry-overlay.log.0


#
# Start the registry node
#
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
