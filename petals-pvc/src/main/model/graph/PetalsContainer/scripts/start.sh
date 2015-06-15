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

if [ ! -e /etc/petals-esb/container-available/${containerId} ]
then
   #
   # Domain definition of the container. We use temporary domain and sub-domain names
   #
   DOMAIN_NAME=`echo ${PetalsContainerBootstrap_0_domainName}_$RANDOM`
   SUBDOMAIN_NAME=`echo ${PetalsContainerBootstrap_0_subdomainName}_$RANDOM`
   
   generate_topology ${DOMAIN_NAME} ${SUBDOMAIN_NAME} ${containerId} ${ip} ${PetalsRegistry_0_ip} \
                     ${PetalsRegistry_0_port} ${PetalsRegistry_0_credentialsGroup} ${PetalsRegistry_0_credentialsPassword} \
                     ${jmxPort} && \
   generate_server_properties ${containerId} && \
   generate_loggers_properties ${containerId} && \
   start_container ${containerId} && \
   attach_container ${ip} ${jmxPort} ${PetalsContainerBootstrap_0_subdomainName} ${PetalsContainerBootstrap_0_containerId} ${PetalsContainerBootstrap_0_ip}
   exit $?
else
   start_container ${containerId}
   exit $?
fi 