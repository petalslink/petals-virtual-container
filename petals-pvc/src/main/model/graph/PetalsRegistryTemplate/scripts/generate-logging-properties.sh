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
# along with this program/library; If not, see <http://directory.fsf.org/wiki/License:BSD_3Clause/>
# for the New BSD License (3-clause license).
#
#############################################################################

cat > /etc/petals-registry/member-available/${ROBOCONF_INSTANCE_NAME}/logging.properties << EOF
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
#
#############################################################################

# Logging Handlers
handlers = java.util.logging.FileHandler

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
