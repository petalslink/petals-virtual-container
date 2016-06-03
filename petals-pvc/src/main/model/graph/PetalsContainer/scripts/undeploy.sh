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

. ./functions.sh

#
# Undeploy the container :
#   - the container must be detached from the PVC domain:
#       - we must restart it because the container is stopped (see Roboconf lifecycle),
#       - next, detach it,
#       - next, stop it.
#   - remove configuration files
#   - uninstall Petals ESB runtime removing all configuration files
#

env

start_container ${ROBOCONF_INSTANCE_NAME} && \
detach_container ${ip} ${jmxPort} && \
stop_container ${ROBOCONF_INSTANCE_NAME} && \
rm -rf /etc/petals-esb/container-available/${ROBOCONF_INSTANCE_NAME} && \
dpkg -P petals-cli petals-esb petals-commons
exit $?
