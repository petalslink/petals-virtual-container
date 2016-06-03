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

env

#
# Start the container
#-----------------------------
# On the first start:
#   - the container configuration is generated,
#   - the container is started.
# On next starts, the container is only started.
#
# To know if it is the first start, we check existence of the directory containing the container configuration files
#

if [ ! -e /etc/petals-esb/container-available/${ROBOCONF_INSTANCE_NAME} ]
then
   generate_topology ${domainName} ${ROBOCONF_INSTANCE_NAME} ${ip} ${PetalsRegistryTemplate_0_ip} \
                     ${PetalsRegistryTemplate_0_port} ${PetalsRegistryTemplate_0_credentialsGroup} ${PetalsRegistryTemplate_0_credentialsPassword} \
                     ${jmxPort} && \
   generate_server_properties ${ROBOCONF_INSTANCE_NAME} && \
   generate_loggers_properties ${ROBOCONF_INSTANCE_NAME} ${enableMonitTraces} && \
   generate_env ${ROBOCONF_INSTANCE_NAME} ${maxHeapSize} && \
   start_container ${ROBOCONF_INSTANCE_NAME}
   exit $?
else
   start_container ${ROBOCONF_INSTANCE_NAME}
   exit $?
fi 
