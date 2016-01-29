#!/bin/sh -x
#
# Copyright (c) 2015-2016 Linagora
#
# This program/library is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 2.1 of the License, or (at your
# option) any later version.
#
# This program/library is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
# for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program/library; If not, see <http://www.gnu.org/licenses/>
# for the GNU Lesser General Public License version 2.1.
#
#############################################################################

env

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
sudo -u petals petals-registry -c file:///etc/petals-registry/member-available/${ROBOCONF_INSTANCE_NAME}/member.properties &

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
