#!/bin/sh -x
#
# Copyright (c) 2015-2016 Linagora
#
# This program/library is free software: you can redistribute it and/or modify
# it under the terms of the New BSD License (3-clause license).
#
# This program/library is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the New BSD License (3-clause license)
# for more details.
#
# You should have received a copy of the New BSD License (3-clause license)
# along with this program/library; If not, see http://directory.fsf.org/wiki/License:BSD_3Clause/
# for the New BSD License (3-clause license).
#
#############################################################################

mkdir -p /etc/petals-registry/member-available/${ROBOCONF_INSTANCE_NAME}
cat > /etc/petals-registry/member-available/${ROBOCONF_INSTANCE_NAME}/cluster.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!--
 Copyright (c) 2015-2016 Linagora

 This program/library is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, either version 2.1 of the License, or (at your
 option) any later version.

 This program/library is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 for more details.

 You should have received a copy of the GNU Lesser General Public License
 along with this program/library; If not, see <http://www.gnu.org/licenses/>
 for the GNU Lesser General Public License version 2.1.
-->
<tns:petals-registry-overlay
   xmlns:tns="http://petals.ow2.org/registry-overlay/configuration/1.0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://petals.ow2.org/registry-overlay/configuration/1.0 petalsRegistryOverlayCfgModel.xsd">
   <tns:credentials>
        <tns:group>${credentialsGroup}</tns:group>
        <tns:password>${credentialsPassword}</tns:password>
   </tns:credentials>
   <tns:members>
        <tns:member id="${ROBOCONF_INSTANCE_NAME}" port="${port}">${ip}</tns:member>
EOF

if [ -z "$PetalsRegistryTemplate_size" ]
then
   i=0
else
   i=$PetalsRegistryTemplate_size
fi
while [ $i -gt 0 ]
do
   i=`expr $i - 1`
   
   remote_memberId_var_name="PetalsRegistryTemplate_${i}_name"
   eval remote_memberId_full=\$${remote_memberId_var_name}
   remote_memberId=`echo ${remote_memberId_full} | cut -d'/' -f 3`
   
   remote_port_var_name="PetalsRegistryTemplate_${i}_port"
   eval remote_port=\$${remote_port_var_name}
   
   remote_ip_var_name="PetalsRegistryTemplate_${i}_ip"
   eval remote_ip=\$${remote_ip_var_name}
   
   cat >> /etc/petals-registry/member-available/${ROBOCONF_INSTANCE_NAME}/cluster.xml << EOF
        <tns:member id="${remote_memberId}" port="${remote_port}">${remote_ip}</tns:member>   
EOF
done

cat >> /etc/petals-registry/member-available/${ROBOCONF_INSTANCE_NAME}/cluster.xml << EOF
   </tns:members>

   <!-- By default, the support of the Hazelcast Management Center is enable -->
   <tns:management-console enable="true">${managementUrl}</tns:management-console>

</tns:petals-registry-overlay>
EOF
