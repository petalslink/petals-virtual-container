#!/bin/sh -x
#
# Copyright (c) 2015 Linagora
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

. ./functions.sh

#
# Start the container
#-----------------------------
# On the first start:
#   - the container configuration is generated,
#   - the container is started,
#   - the container is attached to the PVC sub-domain
# On next starts, the container is only started.
#
# To know if it is the first start, we check existence of the directory containing the container configuration files
#

env

if [ ! -e /etc/petals-esb/container-available/${ROBOCONF_INSTANCE_NAME} ]
then
   #
   # Domain definition of the container. We use temporary domain and sub-domain names
   #
   RANDOM=`tr -cd 0-9 </dev/urandom | head -c 10`
   DOMAIN_NAME=`echo ${PetalsContainerBootstrap_0_domainName}_${RANDOM}`
   SUBDOMAIN_NAME=`echo ${PetalsContainerBootstrap_0_subdomainName}_${RANDOM}`
   BOOTSTRAP_CONTAINER_NAME=`echo ${PetalsContainerBootstrap_0_name} | cut -d'/' -f 3`
   
   generate_topology ${DOMAIN_NAME} ${SUBDOMAIN_NAME} ${ROBOCONF_INSTANCE_NAME} ${ip} ${PetalsRegistryTemplate_0_ip} \
                     ${PetalsRegistryTemplate_0_port} ${PetalsRegistryTemplate_0_credentialsGroup} ${PetalsRegistryTemplate_0_credentialsPassword} \
                     ${jmxPort} && \
   generate_server_properties ${ROBOCONF_INSTANCE_NAME} && \
   generate_loggers_properties ${ROBOCONF_INSTANCE_NAME} && \
   start_container ${ROBOCONF_INSTANCE_NAME} && \
   attach_container ${ip} ${jmxPort} ${PetalsContainerBootstrap_0_subdomainName} ${BOOTSTRAP_CONTAINER_NAME} ${PetalsContainerBootstrap_0_ip}
   exit $?
else
   start_container ${ROBOCONF_INSTANCE_NAME}
   exit $?
fi 