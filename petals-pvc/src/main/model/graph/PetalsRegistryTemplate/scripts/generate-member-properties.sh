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

cat > /etc/petals-registry/member-available/${ROBOCONF_INSTANCE_NAME}/member.properties << EOF
#
# Copyright (c) 2013-2016 Linagora
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
petals.registry.overlay.member.local-identifier = ${ROBOCONF_INSTANCE_NAME}

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

