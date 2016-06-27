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


#
# Starts a container:
#
# Usage:
#   start_container <containerId>
#
# where:
#   <contrainerId> is the identifier of the container to start.
#
# Returns:
#   0: The container is successfully started,
#   1: An error occurs or the container is not started.
#
# Note:
#   The container configuration is expected in the directory /etc/petals-esb/container-available/<containerId>
#
start_container()
{
   CONTAINER_ID=$1
   
   sudo -u petals rm -f /var/log/petals-esb/${containerId}/petals.log
   sudo -u petals petals-esb -u file:///etc/petals-esb/container-available/${CONTAINER_ID}/server.properties -e &
   ret="$?"
   if [ $ret -eq 0 ]
   then
      ret="1"
      try=0
      while [ $ret -ne 0 -a $try -le 30 ]
      do
         sleep 1
         cat /var/log/petals-esb/${CONTAINER_ID}/petals.log | grep "INFO \[Petals.Server] : Server STARTED"
         ret=$?
         try=`expr $try + 1` 
      done
   fi
   if [ $ret -eq 0 ]
   then
      return 0
   else
      return 1
   fi
}

#
# Stops a container:
#
# Usage:
#   stop_container <containerId>
#
# where:
#   <contrainerId> is the base identifier of the container to stop.
#
# Returns:
#   0: The container is successfully stopped,
#   1: An error occurs or the container is not stopped.
#
# Note:
#   The container configuration is expected in the directory /etc/petals-esb/container-available/<containerId>
#
stop_container()
{
   CONTAINER_ID=`ls -1d /var/log/petals-esb/${1}* | cut -d '/' -f 5`
   
   sudo -u petals rm -f /var/log/petals-esb/${CONTAINER_ID}/petals.log
   sudo -u petals petals-esb -u file:///etc/petals-esb/container-available/${CONTAINER_ID}/server.properties -e stop
   ret="$?"
   if [ $ret -eq 0 ]
   then
      ret="1"
      try=0
      while [ $ret -ne 0 -a $try -le 30 ]
      do
         sleep 1
         cat /var/log/petals-esb/${CONTAINER_ID}/petals.log | grep "INFO \[Petals.Server] : Server STOPPED"
         ret=$?
         try=`expr $try + 1` 
      done
   fi
   if [ $ret -eq 0 ]
   then
      return 0
   else
      return 1
   fi
}

#
# Attaches a container to the PVC domain:
#
# Usage:
#   attach_container <containerIp> <jmxPort> <pvcDomain> <targetContainerHost>
#
# where:
#   <contrainerIp> is the host-name or IP address of the container to attach to the PVC domain,
#   <jmxPort> is the JMX port of the container to attach,
#   <pvcDomain> is the domain name of the PVC to join,
#   <targetContainerHost> is the host-name of a container (the same used for <targetContainerName>) already attached to the PVC domain.
#
# Returns:
#   0: The container is successfully attached,
#   1: An error occurs or the container is not attached.
#
# Note:
#   Requires Petals CLI. 
#
attach_container()
{
   CONTAINER_IP=$1
   JMX_PORT=$2
   PVC_DOMAIN=$3
   TARGET_CONTAINER_HOST=$4
   petals-cli -h ${CONTAINER_IP} -n ${JMX_PORT} -u petals -p petals -c -- move-container --target-domain ${PVC_DOMAIN} \
       --target-host ${TARGET_CONTAINER_HOST} --target-port 7700 --target-user petals \
       --target-pwd petals --target-pass-phrase petals -y
   if [ $? -eq 0 ]
   then
      return 0
   else
      return 1
   fi
}

#
# Detaches a container from the PVC domain:
#
# Usage:
#   detach_container <containerIp>
#
# where:
#   <contrainerIp> is the host-name or IP address of the container to detach from the PVC domain,
#   <jmxPort> is the JMX port of the container to attach.
#
# Returns:
#   0: The container is successfully detached,
#   1: An error occurs or the container is not detached.
#
# Note:
#   Requires Petals CLI. 
#
detach_container()
{
   CONTAINER_IP=$1
   JMX_PORT=$2
   petals-cli -h ${CONTAINER_IP} -n ${JMX_PORT} -u petals -p petals -c -- move-container -y
   if [ $? -eq 0 ]
   then
      return 0
   else
      return 1
   fi
}

#
# Generates the topology configuration
#
# Usage:
#   generate-topology <domainName> <containerId> <containerIp> <registryHostIp> <registryHostPort> <registryCredentialsGroup> <registryCredentialsPwd> <jmxPort>
#
# where:
#   <domainName> is the domain name in which the container will run,
#   <contrainerId> is the identifier of the container for which we generate the topology,
#   <containerIp> is the host-name of the container for which we generate the topology,
#   <registryHostIp> is the host-name of a registry member that must be used by the container,
#   <registryHostPort> is the listening port of the registry member that must be used by the container,
#   <registryCredentialsGroup> is the group part of the credentials of the registry to use,
#   <registryCredentialsPwd> is the password part of the credentials of the registry to use,
#   <jmxPort> is the port listening JMX requests.
#
# Returns:
#   0: The topology generation is successfully generated,
#   1: An error occurs.
#
# Note:
#   The container configuration is expected in the directory /etc/petals-esb/container-available/<containerId>
#
generate_topology()
{
   DOMAIN_NAME=$1
   CONTAINER_ID=$2
   CONTAINER_IP=$3
   REGISTRY_HOST_IP=$4
   REGISTRY_HOST_PORT=$5
   REGISTRY_CREDENTIALS_GROUP=$6
   REGISTRY_CREDENTIALS_PWD=$7
   JMX_PORT=$8
   
   
   mkdir -p /etc/petals-esb/container-available/${CONTAINER_ID}
   cat > /etc/petals-esb/container-available/${CONTAINER_ID}/topology.xml << EOF
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
<tns:topology xmlns:tns="http://petals.ow2.org/topology"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://petals.ow2.org/topology petalsTopology.xsd">
	<tns:domain name="${DOMAIN_NAME}" mode="dynamic">
		<tns:description>A sample domain configuration</tns:description>
			
		<!-- Registry implementation to used over the domain, -->
		<!-- The default implementation "Petals Registry Overlay Client" is loaded from the classloader -->
		<!--tns:registry-implementation>org.ow2.petals.microkernel.registry.overlay.RegistryOverlayImpl</tns:registry-implementation--> 
			
		<!-- Containers of the domain -->
		<tns:container name="${CONTAINER_ID}">
			<tns:description>description of the container 0</tns:description>
			<tns:host>${CONTAINER_IP}</tns:host>
			<tns:user>petals</tns:user>
			<tns:password>petals</tns:password>
			<tns:jmx-service>
				<tns:rmi-port>${JMX_PORT}</tns:rmi-port>
			</tns:jmx-service>
			<tns:transport-service>
				<tns:tcp-port>7800</tns:tcp-port>
			</tns:transport-service>
		</tns:container>
			
        <!-- Default configuration of the default registry implementation -->
        <registry:configuration xmlns:registry="http://petals.ow2.org/petals-registry-overlay-client/configuration">
            <registry:group-name>${REGISTRY_CREDENTIALS_GROUP}</registry:group-name>
            <registry:group-password>${REGISTRY_CREDENTIALS_PWD}</registry:group-password>
            <registry:overlay-members>
                <registry:overlay-member port="${REGISTRY_HOST_PORT}">${REGISTRY_HOST_IP}</registry:overlay-member>
            </registry:overlay-members>
        </registry:configuration>
	</tns:domain>
</tns:topology>
EOF
}

#
# Generates the system environment configuration (env.sh)
#
# Usage:
#   generate_env <containerId> <max_heap_size> <snmp_agent_port>
#
# where:
#   <contrainerId> is the identifier of the container for which we generate the system environment configuration.
#   <max_heap_size> is the max size of the JVM Heap
#   <snmp_agent_port>, optional, if set the SNMP agent is enable at JVM level and listens SNMP requests on the given port
#
# Returns:
#   0: The system environment configuration generation is successfully generated,
#   1: An error occurs.
#
# Note:
#   The container configuration is expected in the directory /etc/petals-esb/container-available/<containerId>
#
generate_env()
{
   CONTAINER_ID=$1
   MAX_HEAP_SIZE=$2
   SNMP_AGENT_PORT=$3
   
   if [ -n "${SNMP_AGENT_PORT}" ]
   then
      cat /etc/petals-esb/default-env.sh | \
          sed -e "s/-Xmx[0-9]*[mgMG]/-Xmx${MAX_HEAP_SIZE}/" | \
          sed -e 's/^#\(JAVA_OPTS="$JAVA_OPTS -Dcom\.sun\.management\.snmp\..*$\)/\1/' | \
          sed -e "s/^\(JAVA_OPTS=\"\$JAVA_OPTS -Dcom\.sun\.management\.snmp\.port=\).*$/\1${SNMP_AGENT_PORT}\"/" > /etc/petals-esb/container-available/${CONTAINER_ID}/env.sh
   else
      cat /etc/petals-esb/default-env.sh | sed -e "s/-Xmx[0-9]*[mgMG]/-Xmx${MAX_HEAP_SIZE}/" > /etc/petals-esb/container-available/${CONTAINER_ID}/env.sh
   fi
}

#
# Generates the local container configuration (server.properties)
#
# Usage:
#   generate_server_properties <containerId>
#
# where:
#   <contrainerId> is the identifier of the container for which we generate the local container configuration.
#
# Returns:
#   0: The local container configuration generation is successfully generated,
#   1: An error occurs.
#
# Note:
#   The container configuration is expected in the directory /etc/petals-esb/container-available/<containerId>
#
generate_server_properties()
{
   CONTAINER_ID=$1
   
   cat > /etc/petals-esb/container-available/${CONTAINER_ID}/server.properties << EOF
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


# -----------------------------------------------------------------------
# Petals ESB - General Properties
# -----------------------------------------------------------------------

# This property specifies the name of the container. In distributed mode, this property is mandatory
# and must match a container name in the topology.xml file.
petals.container.name=${CONTAINER_ID}

# This property defines the root directory of all data directories of the current container.
# If not specified, the default values is the directory 'data' contained in the parent directory
# of the directory containing the file 'server.properties'.
petals.data.basedir=/var/lib/petals-esb/\${petals.container.name}

# This property specifies the (absolute) path to the Petals repository.
# Petals holds its JBI configuration in this repository and can recover this configuration from it.
# If not specified, the default repository is '\${petals.data.basedir}/repository'
#petals.repository.path=\${petals.data.basedir}/repository

# This property specifies the (absolute) path to the Petals working area.
# If not specified, the default value is '\${petals.data.basedir}/work'
#petals.work.path=\${petals.data.basedir}/work

# This property defines the configuration file of the logging system. Check the Petals documentation
# for more information about the default value.
#petals.container.log.config.file=/etc/petals-esb/container-available/\${petals.container.name}/logger.properties

# This property defines the environment configuration file. Check the Petals documentation
# for more information about the default value.
petals.environment.config.file=/etc/petals-esb/container-available/${CONTAINER_ID}/env.sh

# This property sets the maximum duration of the processing of a life-cycle operation on a JBI
# components and SAs (start, stop, ...). It prevents from hanging threads. 
petals.task.timeout=120000

# This property is used to activate the control of exchange acceptance by target component when
# the NMR routes messages (see isExchangeWithConsumerOkay and isExchangeWithProviderOkay methods
# in JBI Component interface).
# If not specified, the false value is selected by default.
#petals.exchange.validation=true

# This property is used to isolate the ClassLoaders created for Shared Libraries and Components 
# from the Petals container one.
# It can be useful to avoid concurrent libraries loading issues.
# If not specified, the false value is selected by default
petals.classloaders.isolated=true

# Alternate topology configuration file URL. This value must be a valid URL like :
#  - http://localhost:8080/petals/topology.xml
#  - file:///home/petals/config/topology.xml
#  - or any valid URL (java.net.URL validation)
#
# If not specified, the local topology.xml file is used
#petals.topology.url=

# Pass-phrase needed to get sensible information of other Petals nodes of the topology as JMX credentials.
# It is required to get sensible information and cannot be null or empty. 
petals.topology.passphrase=petals

# Waiting time, in seconds, to acquire the dynamic topology lock distributed over all Petals nodes.
# Default value: 30s. 
#petals.topology.dynamic.lock.wait.time=30

# Waiting time, in milliseconds, before to start the topology pinger. Default value: 2s
#petals.topology.pinger.start-delay=2000

# Delay, in milliseconds, between two runs of the topology pinger. Default value: 5s
#petals.topology.pinger.period-delay=5000

# This property defines the strategy of the router
# Two kind of strategy can be defines: 'highest' or 'random'.
# The following parameters, separated by commas, represent respectively the weighting for a local
# endpoint, the weighting for a remote active endpoint and the weighting for a remote inactive endpoint.
#
# The 'random' strategy chooses an endpoint randomly in function of the defined weightings.
# Every endpoint has a chance to be elected, but the more the weight is strong, the more the endpoint
# can be elected.
#
# The 'highest' strategy chooses an endpoint amongst the endpoints with the strongest weight.
# If not specified, the strategy 'highest,3,2,1' is selected by default
#petals.router.strategy=highest,3,2,1

# This property defines the number of attempt to send a message to an endpoint.
# Several attempts can be done when there is transport failure during the convey of a message
# If not specified, 2 attempts is selected by default.
#petals.router.send.attempt=2

# This property defines the delay between the send attempts, in milliseconds.
# If not specified, 1 second is selected by default.
#petals.router.send.delay=1000


#---------------------------------
# Petals ESB - SSL Connections
#---------------------------------

# This property defines the key password to retrieve the private key.
#petals.ssl.key.password=yourKeyPassword

# This property defines the keystore file where the keys are stored.
#petals.ssl.keystore.file=/yourPath/yourKeystoreFile

# This property defines the keystore password.
#petals.ssl.keystore.password=yourKeystorePassword

# This property defines the truststore file where the signatures are verified.
#petals.ssl.truststore.file=/yourPath/yourTruststoreFile

# This property defines the truststore password.
#petals.ssl.truststore.password=yourTruststorePassword


#----------------------------------------
# Petals ESB - Transporter Configuration
#----------------------------------------

# This property defines the size of the transporter queues. One queue exists by target component.
# By default 10000 messages can be enqueued.
#petals.transport.queue.max-size=10000

# This property defines the max duration, in milliseconds, to wait when the a transporter queue is
# full before to fail. Default value: 2500ms
#petals.transport.queue.offering.timeout=2500

# This property defines the number of message that can be received via TCP at the same time.
# If not specified, '10' receivers is selected by default.
#petals.transport.tcp.receivers=10

# This property defines the number of message that can be send via TCP at the same time, per component.
# If not specified, '10' senders is selected by default.
#petals.transport.tcp.senders=10

# This property defines the timeout to establish a connection, for a sender, in millisecond.
# If not specified, 5000 milliseconds is selected by default.
#petals.transport.tcp.connection.timeout=5000

# This property defines the timeout to send a TCP packet, for a sender, in millisecond.
# If not specified, 5000 milliseconds is selected by default.
#petals.transport.tcp.send.timeout=5000

# This property defines the delay before running the 'sender' eviction thread, in millisecond.
# If not specified, 1 minute is selected by default.
#petals.transport.tcp.send.evictor.delay=60000

# This property defines the delay before an idle 'sender' is set evictable, in millisecond.
# If not specified, 1 minute is selected by default.
#petals.transport.tcp.send.evictable.delay=60000

#--------------------------------------
# Petals ESB - Persistence service
#--------------------------------------
# This property defines the duration of temporary persisted data, such as Message Exchange, in millisecond.
# If not specified, 1 hour is selected by default.
#petals.persistence.duration=3600000

# This property defines the persistence SQL request fetch size. Default value: 10
#petals.persistence.fetch-size=10

# Persistence database configuration.
# Default values:
#   * JDBC Driver: org.hsqldb.jdbcDriver
#   * JDBC URL: jdbc:hsqldb:file:\${petals.work.path}/persistenceService;shutdown=true
#   * JDBC username: SA
#   * JDBC password: <empty>
#petals.persistence.db.driver=org.hsqldb.jdbcDriver
#petals.persistence.db.url=jdbc:hsqldb:file:\${petals.work.path}/persistenceService;shutdown=true
#petals.persistence.db.user=sa
#petals.persistence.db.password=

#--------------------------------------
# Petals ESB - Registry Configuration
#--------------------------------------
# Max size, in endpoint number, of the cache associated to each map of the registry overlay client implementation.
# Default value: 500 endpoints
#org.ow2.petals.microkernel.registry.overlay.RegistryOverlayImpl.map-cache.max-size=500

#--------------------------------------
# Petals ESB - System recovery service
#--------------------------------------

# This property defines the core size of the thread pool used by the system recovery service.
# The default value is '5'.
#petals.recovery.corepoolsize=5

# This property defines the keep alive time, in seconds, of the thread pool used by the system recovery service.
# The default value is '60'. Note: the system recovery service is stopped (and thread pool shutdown) when the
# system recovery is finished.
#petals.recovery.keepalivetime=60
EOF
}

#
# Generates the logging configuration of the container (loggers.properties)
#
# Usage:
#   generate_loggers_properties <containerId> <enableMonitTraces>
#
# where:
#   <contrainerId> is the identifier of the container for which we generate the logging configuration.
#   <enableMonitTraces>, if 'true', the MONIT traces will be enable.
#
# Returns:
#   0: The local container configuration generation is successfully attached,
#   1: An error occurs.
#
# Note:
#   The container configuration is expected in the directory /etc/petals-esb/container-available/<containerId>
#
generate_loggers_properties()
{
   CONTAINER_ID=$1
   ENABLE_MONIT_TRACES=$2
   
   if [ "${ENABLE_MONIT_TRACES}" = "true" ]
   then
      COMPONENTS_LOG_LEVEL="MONIT"
   else
      COMPONENTS_LOG_LEVEL="INFO"
   fi
   
   cat > /etc/petals-esb/container-available/${CONTAINER_ID}/loggers.properties << EOF
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

# Configuration of the log handlers
#####################################
handlers=org.ow2.petals.log.handler.PetalsFileHandler

# Enable PetalsDumperFileHandler to dump message exchange payload content of business traces
#handlers=org.ow2.petals.log.handler.PetalsPayloadDumperFileHandler

# Configuration of the handler PetalsFileHandler
##################################################
org.ow2.petals.log.handler.PetalsFileHandler.level=FINEST
org.ow2.petals.log.handler.PetalsFileHandler.formatter=org.ow2.petals.log.formatter.LogDataFormatter
org.ow2.petals.log.handler.PetalsFileHandler.basedir=/var/log/petals-esb/\${petals.container.name}/
#org.ow2.petals.log.handler.PetalsFileHandler.flows-subdir=flow-monitoring
#org.ow2.petals.log.handler.PetalsFileHandler.logFilename=petals.log

# Configuration of the handler PetalsPayloadDumperFileHandler
########################################################
org.ow2.petals.log.handler.PetalsPayloadDumperFileHandler.level=FINEST
org.ow2.petals.log.handler.PetalsPayloadDumperFileHandler.formatter=org.ow2.petals.log.formatter.LogDataFormatter
org.ow2.petals.log.handler.PetalsPayloadDumperFileHandler.basedir=/var/log/petals-esb/\${petals.container.name}/
#org.ow2.petals.log.handler.PetalsPayloadDumperFileHandler.flows-subdir=flow-monitoring
#org.ow2.petals.log.handler.PetalsPayloadDumperFileHandler.dump-basedir=/var/log/petals-esb/\${petals.container.name}/flow-monitoring
#org.ow2.petals.log.handler.PetalsPayloadDumperFileHandler.logFilename=petals.log

# Configuration of the formatter LogDataFormatter
###################################################
#org.ow2.petals.log.formatter.LogDataFormatter.starting-delimiter=
#org.ow2.petals.log.formatter.LogDataFormatter.ending-delimiter=

##Root level
.level=WARNING

##Petals level
Petals.level=INFO

#Petals.Container.level=FINEST
Petals.Container.Components.level=${COMPONENTS_LOG_LEVEL}

EOF
}
