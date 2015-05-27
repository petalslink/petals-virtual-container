#!/bin/sh -x

. ./env.sh

#
# Install runtime of Petals Registry
#

wget -O ${PETALS_COMMON_DEB_FILE} \
     "http://repository.ow2.org/nexus/service/local/artifact/maven/content?r=snapshots&g=${PETALS_GROUP_ID}&a=${PETALS_COMMONS_DEB_ARTIFACT_ID}&v=${PETALS_COMMONS_DEB_VERSION}&p=deb" && 
  wget -O ${PETALS_REGISTRY_DEB_FILE} \
     "http://repository.ow2.org/nexus/service/local/artifact/maven/content?r=snapshots&g=${PETALS_GROUP_ID}&a=${PETALS_REGISTRY_DEB_ARTIFACT_ID}&v=${PETALS_REGISTRY_DEB_VERSION}&p=deb" &&
  dpkg -i ${PETALS_COMMON_DEB_FILE} ${PETALS_REGISTRY_DEB_FILE}
  
#
# Generate the basic configuration of the Petals Registry
# ----------------
# The basic configuration is a cluster composed of only member. Other members will be added dynamically through the script 'update.sh'
# that will register other members to the current one
#
mkdir -p /etc/petals-registry/member-available/${memberId}
cat > /etc/petals-registry/member-available/${memberId}/cluster.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!--
 Copyright (c) 2013-2015 Linagora

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
        <tns:member id="${memberId}" port="${port}">${ip}</tns:member>
   </tns:members>

   <!-- By default, the support of the Hazelcast Management Center is enable -->
   <tns:management-console enable="false">http://localhost:8080/mancenter</tns:management-console>

</tns:petals-registry-overlay>
EOF



cat > /etc/petals-registry/member-available/${memberId}/member.properties << EOF
#
# Copyright (c) 2013-2015 Linagora
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


# -----------------------------------------------------------------------
# Petals Registry Overlay - Local Member Properties
# -----------------------------------------------------------------------

# This property specifies the name of the local member. This property is mandatory
# and must match a member name in the Petals Registry Overlay configuration file (ie. cluster.xml).
petals.registry.overlay.member.local-identifier = ${memberId}

# This property defines the configuration file of the logging system. Check the Petals Registry Overlay documentation
# for more information about the default value.
#petals.registry.overlay.member.logging-cfg-file=/etc/petals-registry/member-available/\${petals.registry.overlay.member.local-identifier}/logging.properties

# Alternate cluster definition file URL. This value must be a valid URL like :
#  - http://localhost:8080/petals/cluster.xml
#  - file:///home/petals/config/cluster.xml
#  - or any valid URL (java.net.URL validation)
#
# If not specified, the local cluster.xml file is used.
#petals.registry.overlay.cluster-definition=/etc/petals-registry/member-available/\${petals.registry.overlay.member.local-identifier}/cluster.xml

# This property defines the environment configuration file. Check the Petals documentation
# for more information about the default value.
#petals.registry.overlay.member.environment.config.file=/etc/petals-registry/default-env.sh

# This property specifies the JMX port of the current member. Default value: 7750.
#petals.registry.overlay.member.jmx.port = 7750

# This property specifies the username of the JMX credentials. Default value: petals.
#petals.registry.overlay.member.jmx.username = petals

# This property specifies the password of the JMX credentials. Default value: petals.
#petals.registry.overlay.member.jmx.password = petals
EOF



cat > /etc/petals-registry/member-available/${memberId}/logging.properties << EOF
#
# Copyright (c) 2013-2015 Linagora
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

# Logging Handlers
handlers = java.util.logging.ConsoleHandler, java.util.logging.FileHandler

# Console Logging
java.util.logging.ConsoleHandler.level = FINEST
java.util.logging.ConsoleHandler.formatter = org.ow2.petals.log.formatter.LogDataFormatter

# File logging
java.util.logging.FileHandler.pattern = /var/log/petals-registry/petals-registry-overlay.log
java.util.logging.FileHandler.limit = 50000
java.util.logging.FileHandler.count = 5
java.util.logging.FileHandler.formatter = org.ow2.petals.log.formatter.LogDataFormatter

# Configuration of the formatter LogDataFormatter
###################################################
#org.ow2.petals.log.formatter.LogDataFormatter.starting-delimiter=
#org.ow2.petals.log.formatter.LogDataFormatter.ending-delimiter=

.level = INFO
com.hazelcast.level = WARNING
EOF