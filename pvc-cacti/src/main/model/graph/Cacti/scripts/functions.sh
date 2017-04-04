#!/bin/sh -x
#
# Copyright (c) 2016-2017 Linagora
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

CACTI_CLI="/usr/share/cacti/cli"
COOKIE_FILE="/tmp/cacti-post-install-settings.cookie"
PETALS_ROOT_TREE_NAME="Petals domains"

#
# Create all graphs of the given Petals container host
#
# Usage:
#   create_all_graphs_for_one_container <cacti_host> <admin_pwd> <container_name> <container_ip> <container_jmx_port> <container_jmx_user> <container_jmx_pwd>
#
# where:
#   <cacti_host> is the Cacti host name
#   <admin_pwd> is the password of the Cacti user 'admin'
#   <container_name> is the Petals container host name
#   <container_ip> is the Petals container host ip
#   <container_jmx_port> is the Petals container JMX port
#   <container_jmx_user> is the user part of the Petals container JMX credentials
#   <container_jmx_pwd> is the password part of the Petals container JMX credentials
#
# Returns:
#   0: The import succeeds,
#   1: An error occurs.
#
create_all_graphs_for_one_container() {
   CACTI_HOSTNAME=$1
   ADMIN_PWD="$2"
   CONTAINER_NAME="$3"
   CONTAINER_IP="$4"
   CONTAINER_JMX_PORT="$5"
   CONTAINER_JMX_USER="$6"
   CONTAINER_JMX_PWD="$7"
   
   new_petals_host "${CONTAINER_NAME}" "${CONTAINER_IP}" && \
   create_container_tree_entry "${CONTAINER_NAME}" "${CONTAINER_IP}" "${CONTAINER_JMX_PORT}" "${CONTAINER_JMX_USER}" "${CONTAINER_JMX_PWD}" && \
   create_graph_local_transporter_delivered_messages "${CONTAINER_NAME}" "${CONTAINER_JMX_PORT}" "${CONTAINER_JMX_USER}" "${CONTAINER_JMX_PWD}" && \
   create_graphs_remote_transporter_outgoing_messages "${CONTAINER_NAME}" && \
   create_graphs_remote_transporter_outgoing_connections "${CONTAINER_NAME}" && \
   create_graphs_remote_transporter_incoming_messages "${CONTAINER_NAME}" && \
   create_graphs_remote_transporter_incoming_connections "${CONTAINER_NAME}"

# We must use an Oracle JVM to have an embedded SNMP agent:
#   new_data_source ${CACTI_HOSTNAME} "${ADMIN_PWD}" "jvmGCcount" "${CONTAINER_NAME}" && \
#   new_data_source ${CACTI_HOSTNAME} "${ADMIN_PWD}" "jvmGCtime" "${CONTAINER_NAME}" && \
#   new_data_source ${CACTI_HOSTNAME} "${ADMIN_PWD}" "jvmMemoryHeapCommitted" "${CONTAINER_NAME}" && \
#   new_data_source ${CACTI_HOSTNAME} "${ADMIN_PWD}" "jvmMemoryHeapMaxSize" "${CONTAINER_NAME}" && \
#   new_data_source ${CACTI_HOSTNAME} "${ADMIN_PWD}" "jvmMemoryHeapUsed" "${CONTAINER_NAME}" && \
#   new_data_source ${CACTI_HOSTNAME} "${ADMIN_PWD}" "jvmMemoryNonHeapCommited" "${CONTAINER_NAME}" && \
#   new_data_source ${CACTI_HOSTNAME} "${ADMIN_PWD}" "jvmMemoryNonHeapMaxSize" "${CONTAINER_NAME}" && \
#   new_data_source ${CACTI_HOSTNAME} "${ADMIN_PWD}" "jvmMemoryNonHeapUsed" "${CONTAINER_NAME}" && \
#   new_data_source ${CACTI_HOSTNAME} "${ADMIN_PWD}" "jvmThreadDaemonCount" "${CONTAINER_NAME}" && \
#   new_data_source ${CACTI_HOSTNAME} "${ADMIN_PWD}" "jvmThreadLiveCount" "${CONTAINER_NAME}" && \
#   new_data_source ${CACTI_HOSTNAME} "${ADMIN_PWD}" "jvmThreadPeakCount" "${CONTAINER_NAME}" && \
#   new_data_source ${CACTI_HOSTNAME} "${ADMIN_PWD}" "jvmThreadTotalStartedCount" "${CONTAINER_NAME}"
}

#
# Update graphs of the given Petals container host according to:
#    - a new remote container known
#
# Usage:
#   update_all_graphs_for_one_container <container_name> <remote-container-name> <remote-container-ip>
#
# where:
#   <container_name> is @IP of the Petals container
#   <remote-container-name> is the identifier of the new remote Petals container known
#   <remote-container-ip> is the @IP of the new remote Petals container known
#
# Returns:
#   0: The import succeeds,
#   1: An error occurs.
#
update_all_graphs_for_one_container() {
   CONTAINER_IP="$1"
   REMOTE_CONTAINER_NAME="$2"
   REMOTE_CONTAINER_IP="$3"
   
   create_one_graph_remote_transporter_outgoing_messages "${CONTAINER_IP}" "${REMOTE_CONTAINER_NAME}"
   create_one_graph_remote_transporter_outgoing_connections "${CONTAINER_IP}" "${REMOTE_CONTAINER_NAME}"
   create_one_graph_remote_transporter_incoming_messages "${CONTAINER_IP}" "${REMOTE_CONTAINER_IP}"
   create_one_graph_remote_transporter_incoming_connections "${CONTAINER_IP}" "${REMOTE_CONTAINER_IP}"
}

#
# Create the graph "Delivered messages of the local transporter" of the given container.
#
# Usage:
#   create_graph_local_transporter_delivered_messages <container_ip> <container_jmx_port> <container_jmx_user> <container_jmx_wdd>
#
# where:
#   <container_ip> is @IP of the Petals container
#   <container_jmx_port> is the Petals container JMX port
#   <container_jmx_user> is the user part of the Petals container JMX credentials
#   <container_jmx_pwd> is the password part of the Petals container JMX credentials
#
# Returns:
#   0: The container graph creations succeed,
#   1: An error occurs.
#
create_graph_local_transporter_delivered_messages() {
   CONTAINER_IP="$1"
   CONTAINER_JMX_PORT="$2"
   CONTAINER_JMX_USER="$3"
   CONTAINER_JMX_PWD="$4"

   DEVICE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-hosts | grep -e "\s${CONTAINER_IP}" | cut -f1`
   GRAPH_TEMPLATE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-graph-templates | grep -e "\sPetals - Container - Local transporter - Delivered messages" | cut -f1`
   
   php -q ${CACTI_CLI}/add_graphs.php --graph-type=cg --graph-template-id=${GRAPH_TEMPLATE_ID} --host-id=${DEVICE_ID} --input-fields="petals_jmx_port=${CONTAINER_JMX_PORT} petals_jmx_user=${CONTAINER_JMX_USER} petals_jmx_pwd=${CONTAINER_JMX_PWD}"
}

#
# Create the graphs "Delivered outgoing messages of the remote transporter" of the given container, one graph per remote containers known at this time.
#
# Usage:
#   create_graphs_remote_transporter_outgoing_messages <container_ip>
#
# where:
#   <container_ip> is @IP of the Petals container
#
# Returns:
#   0: The container graph creations succeed,
#   1: An error occurs.
#
create_graphs_remote_transporter_outgoing_messages() {
   CONTAINER_IP="$1"

   # Associate the data query to the device linked to the given container
   DEVICE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-hosts | grep -e "\s${CONTAINER_IP}" | cut -f1`
   GRAPH_TEMPLATE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-graph-templates | grep -e "\sPetals - Container - Remote transporter - Outgoing delivered messages" | cut -f1`
   DATA_QUERY_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-snmp-queries | grep -e "\sPetals - Container - Remote transporter - Outgoing delivered messages" | cut -f1`
   DATA_QUERY_TYPE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-query-types --snmp-query-id=${DATA_QUERY_ID} | grep -e "\sPetals - Container - Remote transporter - Outgoing delivered messages" | cut -f1`
   REMOTE_CONTAINERS_NAME=`php ${CACTI_CLI}/add_graphs.php --list-snmp-values --host-id=${DEVICE_ID} --snmp-query-id=${DATA_QUERY_ID} --snmp-field=filterName | tail -n+2`
   for REMOTE_CONTAINER_NAME in ${REMOTE_CONTAINERS_NAME}
   do
      create_one_graph_remote_transporter_outgoing_messages "${CONTAINER_IP}" "${REMOTE_CONTAINER_NAME}"
   done
}

#
# Create the graph "Delivered outgoing messages of the remote transporter" of the given container, and for the given remote containers.
#
# Usage:
#   create_graph_remote_transporter_outgoing_messages <container_ip> <remote-container-name>
#
# where:
#   <container_ip> is @IP of the Petals container
#   <remote-container-name> is the remote Petals container identifier
#
# Returns:
#   0: The container graph creations succeed,
#   1: An error occurs.
#
create_one_graph_remote_transporter_outgoing_messages() {
   CONTAINER_IP="$1"
   REMOTE_CONTAINER_NAME="$2"

   DEVICE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-hosts | grep -e "\s${CONTAINER_IP}" | cut -f1`
   GRAPH_TEMPLATE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-graph-templates | grep -e "\sPetals - Container - Remote transporter - Outgoing delivered messages" | cut -f1`
   DATA_QUERY_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-snmp-queries | grep -e "\sPetals - Container - Remote transporter - Outgoing delivered messages" | cut -f1`
   DATA_QUERY_TYPE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-query-types --snmp-query-id=${DATA_QUERY_ID} | grep -e "\sPetals - Container - Remote transporter - Outgoing delivered messages" | cut -f1`
   php -q ${CACTI_CLI}/add_graphs.php --host-id=${DEVICE_ID} --graph-type=ds --graph-template-id=${GRAPH_TEMPLATE_ID} --snmp-query-id=${DATA_QUERY_ID} --snmp-query-type-id=${DATA_QUERY_TYPE_ID} --snmp-field=filterName --snmp-value=${REMOTE_CONTAINER_NAME}
}

#
# Create the graphs "Delivered incoming messages from the remote transporter" of the given container, one graph per remote containers known at this time.
#
# Usage:
#   create_graphs_remote_transporter_incoming_messages <container_ip>
#
# where:
#   <container_ip> is @IP of the Petals container
#
# Returns:
#   0: The container graph creations succeed,
#   1: An error occurs.
#
create_graphs_remote_transporter_incoming_messages() {
   CONTAINER_IP="$1"

   # Associate the data query to the device linked to the given container
   DEVICE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-hosts | grep -e "\s${CONTAINER_IP}" | cut -f1`
   GRAPH_TEMPLATE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-graph-templates | grep -e "\sPetals - Container - Remote transporter - Incoming delivered messages" | cut -f1`
   DATA_QUERY_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-snmp-queries | grep -e "\sPetals - Container - Remote transporter - Incoming delivered messages" | cut -f1`
   DATA_QUERY_TYPE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-query-types --snmp-query-id=${DATA_QUERY_ID} | grep -e "\sPetals - Container - Remote transporter - Incoming delivered messages" | cut -f1`
   REMOTE_CONTAINERS_IP=`php ${CACTI_CLI}/add_graphs.php --list-snmp-values --host-id=${DEVICE_ID} --snmp-query-id=${DATA_QUERY_ID} --snmp-field=filterName | tail -n+2`
   for REMOTE_CONTAINER_IP in ${REMOTE_CONTAINERS_IP}
   do
      create_one_graph_remote_transporter_incoming_messages "${CONTAINER_IP}" "${REMOTE_CONTAINER_IP}"
   done
}

#
# Create the graph "Delivered incoming messages of the remote transporter" of the given container, and for the given remote containers.
#
# Usage:
#   create_one_graph_remote_transporter_incoming_messages <container_ip> <remote-container-ip>
#
# where:
#   <container_ip> is @IP of the Petals container
#   <remote-container-ip> is @IP of the remote Petals container
#
# Returns:
#   0: The container graph creations succeed,
#   1: An error occurs.
#
create_one_graph_remote_transporter_incoming_messages() {
   CONTAINER_IP="$1"
   REMOTE_CONTAINER_IP="$2"

   DEVICE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-hosts | grep -e "\s${CONTAINER_IP}" | cut -f1`
   GRAPH_TEMPLATE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-graph-templates | grep -e "\sPetals - Container - Remote transporter - Incoming delivered messages" | cut -f1`
   DATA_QUERY_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-snmp-queries | grep -e "\sPetals - Container - Remote transporter - Incoming delivered messages" | cut -f1`
   DATA_QUERY_TYPE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-query-types --snmp-query-id=${DATA_QUERY_ID} | grep -e "\sPetals - Container - Remote transporter - Incoming delivered messages" | cut -f1`
   php -q ${CACTI_CLI}/add_graphs.php --host-id=${DEVICE_ID} --graph-type=ds --graph-template-id=${GRAPH_TEMPLATE_ID} --snmp-query-id=${DATA_QUERY_ID} --snmp-query-type-id=${DATA_QUERY_TYPE_ID} --snmp-field=filterName --snmp-value=${REMOTE_CONTAINER_IP}
}

#
# Create the graphs "Incoming connections from the remote transporter" of the given container, one graph per remote containers known at this time.
#
# Usage:
#   create_graphs_remote_transporter_incoming_connections <container_ip>
#
# where:
#   <container_ip> is @IP of the Petals container
#
# Returns:
#   0: The container graph creations succeed,
#   1: An error occurs.
#
create_graphs_remote_transporter_incoming_connections() {
   CONTAINER_IP="$1"

   # Associate the data query to the device linked to the given container
   DEVICE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-hosts | grep -e "\s${CONTAINER_IP}" | cut -f1`
   GRAPH_TEMPLATE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-graph-templates | grep -e "\sPetals - Container - Remote transporter - Incoming connections" | cut -f1`
   DATA_QUERY_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-snmp-queries | grep -e "\sPetals - Container - Remote transporter - Incoming connections" | cut -f1`
   DATA_QUERY_TYPE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-query-types --snmp-query-id=${DATA_QUERY_ID} | grep -e "\sPetals - Container - Remote transporter - Incoming connections" | cut -f1`
   REMOTE_CONTAINERS_IP=`php ${CACTI_CLI}/add_graphs.php --list-snmp-values --host-id=${DEVICE_ID} --snmp-query-id=${DATA_QUERY_ID} --snmp-field=filterName | tail -n+2`
   for REMOTE_CONTAINER_IP in ${REMOTE_CONTAINERS_IP}
   do
      create_one_graph_remote_transporter_incoming_connections "${CONTAINER_IP}" "${REMOTE_CONTAINER_IP}"
   done
}

#
# Create the graph "Incoming connections of the remote transporter" of the given container, and for the given remote containers.
#
# Usage:
#   create_one_graph_remote_transporter_incoming_connections <container_ip> <remote-container-ip>
#
# where:
#   <container_ip> is @IP of the Petals container
#   <remote-container-ip> is @IP of the remote Petals container
#
# Returns:
#   0: The container graph creations succeed,
#   1: An error occurs.
#
create_one_graph_remote_transporter_incoming_connections() {
   CONTAINER_IP="$1"
   REMOTE_CONTAINER_IP="$2"

   DEVICE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-hosts | grep -e "\s${CONTAINER_IP}" | cut -f1`
   GRAPH_TEMPLATE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-graph-templates | grep -e "\sPetals - Container - Remote transporter - Incoming connections" | cut -f1`
   DATA_QUERY_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-snmp-queries | grep -e "\sPetals - Container - Remote transporter - Incoming connections" | cut -f1`
   DATA_QUERY_TYPE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-query-types --snmp-query-id=${DATA_QUERY_ID} | grep -e "\sPetals - Container - Remote transporter - Incoming connections" | cut -f1`
   php -q ${CACTI_CLI}/add_graphs.php --host-id=${DEVICE_ID} --graph-type=ds --graph-template-id=${GRAPH_TEMPLATE_ID} --snmp-query-id=${DATA_QUERY_ID} --snmp-query-type-id=${DATA_QUERY_TYPE_ID} --snmp-field=filterName --snmp-value=${REMOTE_CONTAINER_IP}
}

#
# Create the graphs "Outgoing connections from the remote transporter" of the given container, one graph per remote containers known at this time.
#
# Usage:
#   create_graphs_remote_transporter_outgoing_connections <container_ip>
#
# where:
#   <container_ip> is @IP of the Petals container
#
# Returns:
#   0: The container graph creations succeed,
#   1: An error occurs.
#
create_graphs_remote_transporter_outgoing_connections() {
   CONTAINER_IP="$1"

   # Associate the data query to the device linked to the given container
   DEVICE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-hosts | grep -e "\s${CONTAINER_IP}" | cut -f1`
   GRAPH_TEMPLATE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-graph-templates | grep -e "\sPetals - Container - Remote transporter - Outgoing connections" | cut -f1`
   DATA_QUERY_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-snmp-queries | grep -e "\sPetals - Container - Remote transporter - Outgoing connections" | cut -f1`
   DATA_QUERY_TYPE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-query-types --snmp-query-id=${DATA_QUERY_ID} | grep -e "\sPetals - Container - Remote transporter - Outgoing connections" | cut -f1`
   REMOTE_CONTAINERS_NAME=`php ${CACTI_CLI}/add_graphs.php --list-snmp-values --host-id=${DEVICE_ID} --snmp-query-id=${DATA_QUERY_ID} --snmp-field=filterName | tail -n+2`
   for REMOTE_CONTAINER_NAME in ${REMOTE_CONTAINERS_NAME}
   do
      create_one_graph_remote_transporter_outgoing_connections "${CONTAINER_IP}" "${REMOTE_CONTAINER_NAME}"
   done
}

#
# Create the graph "Outgoing connections of the remote transporter" of the given container, and for the given remote containers.
#
# Usage:
#   create_one_graph_remote_transporter_outgoing_connections <container_ip> <remote-container-name>
#
# where:
#   <container_ip> is @IP of the Petals container
#   <remote-container-name> is the remote Petals container identifier
#
# Returns:
#   0: The container graph creations succeed,
#   1: An error occurs.
#
create_one_graph_remote_transporter_outgoing_connections() {
   CONTAINER_IP="$1"
   REMOTE_CONTAINER_NAME="$2"

   DEVICE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-hosts | grep -e "\s${CONTAINER_IP}" | cut -f1`
   GRAPH_TEMPLATE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-graph-templates | grep -e "\sPetals - Container - Remote transporter - Outgoing connections" | cut -f1`
   DATA_QUERY_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-snmp-queries | grep -e "\sPetals - Container - Remote transporter - Outgoing connections" | cut -f1`
   DATA_QUERY_TYPE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-query-types --snmp-query-id=${DATA_QUERY_ID} | grep -e "\sPetals - Container - Remote transporter - Outgoing connections" | cut -f1`
   php -q ${CACTI_CLI}/add_graphs.php --host-id=${DEVICE_ID} --graph-type=ds --graph-template-id=${GRAPH_TEMPLATE_ID} --snmp-query-id=${DATA_QUERY_ID} --snmp-query-type-id=${DATA_QUERY_TYPE_ID} --snmp-field=filterName --snmp-value=${REMOTE_CONTAINER_NAME}
}

#
# Create a container entry in the graph tree
#
# Usage:
#   create_container_tree_entry <container_name> <container_ip> <container_jmx_port> <container_jmx_user> <container_jmx_pwd>
#
# where:
#   <container_name> is the Petals container host name
#   <container_ip> is the Petals container host ip
#   <container_jmx_port> is the Petals container JMX port
#   <container_jmx_user> is the user part of the Petals container JMX credentials
#   <container_jmx_pwd> is the password part of the Petals container JMX credentials
#
# Returns:
#   0: The container graph creations succeed,
#   1: An error occurs.
#
create_container_tree_entry() {
   CONTAINER_NAME="$1"
   CONTAINER_IP="$2"
   CONTAINER_JMX_PORT="$3"
   CONTAINER_JMX_USER="$4"
   CONTAINER_JMX_PWD="$5"

   # Create the tree for all Petals domains, if needed
   PETALS_TREE_ID=`php -q ${CACTI_CLI}/add_tree.php --list-trees | grep "${PETALS_ROOT_TREE_NAME}" | cut -f1`
   if [ -z "${PETALS_TREE_ID}" ]
   then
      php -q ${CACTI_CLI}/add_tree.php --type=tree --name="${PETALS_ROOT_TREE_NAME}" --sort-method=alpha
      PETALS_TREE_ID=`php -q ${CACTI_CLI}/add_tree.php --list-trees | grep "${PETALS_ROOT_TREE_NAME}" | cut -f1`
   fi

   # Create the sub-tree for the Petals domain of the given container, if needed
   DOMAIN_NAME=`petals-cli -h ${CONTAINER_IP} -n ${CONTAINER_JMX_PORT} -u ${CONTAINER_JMX_USER} -p ${CONTAINER_JMX_PWD} -c -- topology-list | grep "Domain: " | cut -f2 -d' '`
   DOMAIN_TREE_ID=`php -q ${CACTI_CLI}/add_tree.php --list-nodes --tree-id=${PETALS_TREE_ID} | grep -e "\sN/A\s${DOMAIN_NAME}" | cut -f2`
   if [ -z "${DOMAIN_TREE_ID}" ]
   then
      php -q ${CACTI_CLI}/add_tree.php --type=node --node-type=header --name="${DOMAIN_NAME}" --tree-id=${PETALS_TREE_ID} && \
      DOMAIN_TREE_ID=`php -q ${CACTI_CLI}/add_tree.php --list-nodes --tree-id=${PETALS_TREE_ID} | grep -e "\sN/A\s${DOMAIN_NAME}" | cut -f2`
   fi

   # Create the node for the given container, if needed
   HOST_ID=`php -q ${CACTI_CLI}/add_tree.php --list-hosts | grep -e "\s${CONTAINER_NAME}" | cut -f1`
   CONTAINER_NODE_ID=`php -q ${CACTI_CLI}/add_tree.php --list-nodes --tree-id=${PETALS_TREE_ID} | grep -e "^Host\s[0-9]*\s${DOMAIN_TREE_ID}N/A\s${CONTAINER_IP}" | cut -f2`
   if [ -z "${CONTAINER_NODE_ID}" ]
   then
      php -q ${CACTI_CLI}/add_tree.php --type=node --node-type=host --parent-node=${DOMAIN_TREE_ID} --tree-id=${PETALS_TREE_ID} --host-id=${HOST_ID}
   fi
}

#
# Import template file
#
# Note: this function uses Curl to interact with Cacti UI
#
# Usage:
#   import_template_file <cacti_host> <admin_pwd> <xml_file_path>
#
# where:
#   <cacti_host> is the Cacti host name
#   <admin_pwd> is the password of the Cacti user 'admin'
#   <xml_file_path> is the path of the XML file to import
#
# Returns:
#   0: The import succeeds,
#   1: An error occurs.
#
import_template_file()
{
   CACTI_HOSTNAME=$1
   ADMIN_PWD="$2"
   XML_FILE="$3"
   rm -f ${COOKIE_FILE}
   CSRF_MAGIC=`curl -L --request GET "http://${CACTI_HOSTNAME}/cacti/" -c ${COOKIE_FILE} | sed -n 's/.*name=.__csrf_magic.\s\+value="\(sid:[^"]*\).*/\1/p'` && \
   curl -L "http://${CACTI_HOSTNAME}/cacti/index.php" --referer "http://${CACTI_HOSTNAME}/cacti/" -b ${COOKIE_FILE} -c ${COOKIE_FILE} \
        --data "__csrf_magic=${CSRF_MAGIC}" \
        --data "action=login" \
        --data "login_username=admin" \
        --data "login_password=${ADMIN_PWD}" && \
   CSRF_MAGIC=`curl -L "http://${CACTI_HOSTNAME}/cacti/templates_import.php" --referer "http://${CACTI_HOSTNAME}/cacti/templates_import.php" -b ${COOKIE_FILE} -c ${COOKIE_FILE} | \
               sed -n 's/.*name=.__csrf_magic.\s\+value="\(sid:[^"]*\).*/\1/p'` && \
   curl -L "http://${CACTI_HOSTNAME}/cacti/templates_import.php" --referer "http://${CACTI_HOSTNAME}/cacti/templates_import.php" -b ${COOKIE_FILE} -c ${COOKIE_FILE} \
        -F "__csrf_magic=${CSRF_MAGIC}" \
        -F "action=save" \
        -F "import_file=@${XML_FILE}; filename=${XML_FILE}" \
        -F "import_text=" \
        -F "import_rra=1" \
        -F "rra_id[]=1" \
        -F "rra_id[]=2" \
        -F "rra_id[]=3" \
        -F "rra_id[]=4" \
        -F "save_component_import=1"
   if [ $? -eq 0 ]
   then
      return 0
   else
      return 1
   fi
}

#
# Create a new Petals container host
#
# Note: this function uses Cacti CLI
#
# Usage:
#   new_petals_host <container-name> <container-ip>
#
# where:
#   <container-name> is the name of the container
#   <container-ip> is the IP of the container
#
# Returns:
#   0: The data query is successfully created,
#   1: An error occurs.
#
new_petals_host()
{
   CONTAINER_NAME="$1"
   CONTAINER_IP="$2"

   PETALS_HOST_TEMPLATE_ID=`php -q ${CACTI_CLI}/add_device.php --list-host-templates | grep "Petals container Host" | cut -f1` && \
   php -q ${CACTI_CLI}/add_device.php --description="${CONTAINER_NAME}" --ip="${CONTAINER_IP}" --template="${PETALS_HOST_TEMPLATE_ID}" --avail=ping --ping_method=tcp
   return $?
}

#
# Create a new Data Query where the data input method is 'Get Script Data (Indexed)'
#
# Note: this function uses Curl to interact with Cacti UI
#
# Usage:
#   new_script_data_query <cacti_host> <admin_pwd> <name> <description> <xml_path>
#
# where:
#   <cacti_host> is the Cacti host name
#   <admin_pwd> is the password of the Cacti user 'admin'
#   <name> is the name of the data query
#   <description> is the description of the data query
#   <xml_path> is the path of the XML file
#
# Returns:
#   0: The data query is successfully created,
#   1: An error occurs.
#
new_script_data_query()
{
   CACTI_HOSTNAME=$1
   ADMIN_PWD="$2"
   DATA_QUERY_NAME="$3"
   DATA_QUERY_DESCR="$4"
   DATA_QUERY_PATH="$5"
   rm -f ${COOKIE_FILE}
   CSRF_MAGIC=`curl -L --request GET "http://${CACTI_HOSTNAME}/cacti/" -c ${COOKIE_FILE} | sed -n 's/.*name=.__csrf_magic.\s\+value="\(sid:[^"]*\).*/\1/p'` && \
   curl -L "http://${ip}/cacti/index.php" --referer "http://${CACTI_HOSTNAME}/cacti/" -b ${COOKIE_FILE} -c ${COOKIE_FILE} \
        --data "__csrf_magic=${CSRF_MAGIC}" \
        --data "action=login" \
        --data "login_username=admin" \
        --data "login_password=${ADMIN_PWD}" && \
   CSRF_MAGIC=`curl -L "http://${CACTI_HOSTNAME}/cacti/data_queries.php?action=edit" --referer "http://${CACTI_HOSTNAME}/cacti/data_queries.php" -b ${COOKIE_FILE} -c ${COOKIE_FILE} | \
               sed -n 's/.*name=.__csrf_magic.\s\+value="\(sid:[^"]*\).*/\1/p'` && \
   curl -L "http://${CACTI_HOSTNAME}/cacti/data_queries.php" --referer "http://${CACTI_HOSTNAME}/cacti/data_queries.php?action=edit" -b ${COOKIE_FILE} -c ${COOKIE_FILE} \
        --data "__csrf_magic=${CSRF_MAGIC}" \
        --data "action=save" \
        --data "id=0" \
        --data "save_component_snmp_query=1" \
        --data-urlencode "name=${DATA_QUERY_NAME}" \
        --data-urlencode "description=${DATA_QUERY_DESCR}" \
        --data-urlencode "xml_path=${DATA_QUERY_PATH}" \
        --data-urlencode "data_input_id=11"
   if [ $? -eq 0 ]
   then
      return 0
   else
      return 1
   fi
}

#
# Create a new Data Source
#
# Note: this function uses Curl to interact with Cacti UI
#
# Usage:
#   new_data_source <cacti_host> <admin_pwd> <data_template> <host>
#
# where:
#   <cacti_host> is the Cacti host name
#   <admin_pwd> is the password of the Cacti user 'admin'
#   <data_template> is the data template name
#   <host> is the Petals container host
#
# Returns:
#   0: The data source is successfully created,
#   1: An error occurs.
#
new_data_source()
{
   CACTI_HOSTNAME=$1
   ADMIN_PWD="$2"
   DATA_TEMPLATE_NAME="$3"
   DEVICE_NAME="$4"
   rm -f ${COOKIE_FILE}
   CSRF_MAGIC=`curl -L --request GET "http://${CACTI_HOSTNAME}/cacti/" -c ${COOKIE_FILE} | sed -n 's/.*name=.__csrf_magic.\s\+value="\(sid:[^"]*\).*/\1/p'` && \
   curl -L "http://${ip}/cacti/index.php" --referer "http://${CACTI_HOSTNAME}/cacti/" -b ${COOKIE_FILE} -c ${COOKIE_FILE} \
        --data "__csrf_magic=${CSRF_MAGIC}" \
        --data "action=login" \
        --data "login_username=admin" \
        --data "login_password=${ADMIN_PWD}" && \
   DATA_TEMPLATE_ID=`curl -L "http://${CACTI_HOSTNAME}/cacti/data_templates.php" --referer "http://${CACTI_HOSTNAME}/cacti/" -b ${COOKIE_FILE} -c ${COOKIE_FILE} | \
               sed -n "s/.*href='data_templates.php?action=template_edit&amp;id=\([0-9]*\)'>${DATA_TEMPLATE_NAME}<.*/\1/p"` && \
   DEVICE_ID=`php -q ${CACTI_CLI}/add_data_query.php --list-hosts | grep "${DEVICE_NAME}" | cut -f1` && \
   CSRF_MAGIC=`curl -L "http://${CACTI_HOSTNAME}/cacti/data_sources.php?action=ds_edit&host_id=-1" --referer "http://${CACTI_HOSTNAME}/cacti/data_sources.php" -b ${COOKIE_FILE} -c ${COOKIE_FILE} | \
               sed -n 's/.*name=.__csrf_magic.\s\+value="\(sid:[^"]*\).*/\1/p'` && \
   curl -L "http://${CACTI_HOSTNAME}/cacti/data_sources.php" --referer "http://${CACTI_HOSTNAME}/cacti/data_sources.php?action=ds_edit&host_id=-1" -b ${COOKIE_FILE} -c ${COOKIE_FILE} \
        --data "__csrf_magic=${CSRF_MAGIC}" \
        --data "action=save" \
        --data "save_component_data_source_new=1" \
        --data-urlencode "_data_template_id=0" \
        --data-urlencode "_host_id=-1" \
        --data-urlencode "_data_input_id=0" \
        --data-urlencode "data_template_data_id=0" \
        --data-urlencode "local_data_template_data_id=0" \
        --data-urlencode "local_data_id=0" \
        --data-urlencode "data_template_id=${DATA_TEMPLATE_ID}" \
        --data-urlencode "host_id=${DEVICE_ID}"
   if [ $? -eq 0 ]
   then
      return 0
   else
      return 1
   fi
}
