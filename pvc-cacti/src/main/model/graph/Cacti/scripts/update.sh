#!/bin/sh -x
#
# Copyright (c) 2016 Linagora
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

. ./functions.sh

env

#
# Update all graphs of all other containers against the given new container
#
# Usage:
#   update_graphs_of_all_other_containers <container_identifier> <container_ip>
#
# where:
#   <container_identifier> is the identifier of the new Petals container
#   <container_ip> is the @IP of the new Petals container
#
# Returns:
#   0: The container graph creations succeed,
#   1: An error occurs.
#

update_graphs_of_all_other_containers()
{
   NEW_CONTAINER_NAME=$1
   NEW_CONTAINER_IP=$2

   if [ -z "${ESB_size}" ]
   then
      i=0
   else
      i=${ESB_size}
   fi

   # We iterate over all Petals containers except the new one
   while [ $i -gt 0 ]
   do
      i=`expr $i - 1`
      
      container_name_var_name="ESB_${i}_name"
      eval container_name_full=\$${container_name_var_name}
      container_name=`echo ${container_name_full} | cut -d'/' -f 3`

      container_ip_var_name="ESB_${i}_container_ip"
      eval container_ip=\$${container_ip_var_name}
      if [ -n "${container_ip}" ]
      then
         # The Roboconf component is a Petals container, we update its graphs
         if [ "${container_name}" != "${NEW_CONTAINER_NAME}" ]
         then
            DEVICE_ID=`php -q ${CACTI_CLI}/add_graphs.php --list-hosts | grep -e "\s${container_ip}" | cut -f1`
            php -q ${CACTI_CLI}/poller_reindex_hosts.php --id=${DEVICE_ID}
            update_all_graphs_for_one_container "${container_ip}" "${NEW_CONTAINER_NAME}" "${NEW_CONTAINER_IP}"
         fi
      else
         # TODO: update graphs for other Roboconf components of the PVC
         echo "The Roboconf component is not a Petals container"
      fi
   done
}

if [ "${ROBOCONF_IMPORT_CHANGED_COMPONENT}" = "ESB" ]
then
   # It's a configuration change of Roboconf application "ESB"
   # TODO: Simplifie this algorithm when https://github.com/roboconf/roboconf-platform/issues/589 will be fixed
   CONTAINER_NAME=""
   CONTAINER_IDX=0
   updated_instance_name=`echo ${ROBOCONF_IMPORT_CHANGED_INSTANCE_PATH} | cut -d'/' -f 3`
   i=0
   while [ "${i}" -lt ${ESB_size} ]
   do
      container_jmxPort_var_name="ESB_${i}_container_jmxPort"
      eval container_jmxPort=\$${container_jmxPort_var_name}
      if [ -n "${container_jmxPort}" ]
      then
         current_container_name_var_name="ESB_${i}_name"
         eval current_container_name_full=\$${current_container_name_var_name}
         current_container_name=`echo ${current_container_name_full} | cut -d'/' -f 3`
         if [ "${updated_instance_name}" = "${current_container_name}" ]
         then
            # The configuration changed is due to a Petals container
            CONTAINER_NAME=`echo ${current_container_name}`
            CONTAINER_IDX=`echo ${i}`
         fi
      fi
      i=`expr ${i} + 1`
   done

   if [ -n "${CONTAINER_NAME}" ]
   then
      echo "Configuration change initiated by a Petals container"
      if [ "${ROBOCONF_UPDATE_STATUS}" = "DEPLOYED_STARTED" ]
      then
         # A Petals container was started, perhaps its a new Petals container
         CONTAINER_ALREADY_DECLARED=`php -q ${CACTI_CLI}/add_graphs.php --list-hosts | grep -e "\s${CONTAINER_NAME}"`
         if [ -z "${CONTAINER_ALREADY_DECLARED}" ]
         then
            # A new Petals container was started
            container_ip_var_name="ESB_${CONTAINER_IDX}_container_ip"
            eval container_ip=\$${container_ip_var_name}
      
            container_jmxPort_var_name="ESB_${CONTAINER_IDX}_container_jmxPort"
            eval container_jmxPort=\$${container_jmxPort_var_name}
      
            container_jmxUser_var_name="ESB_${CONTAINER_IDX}_container_jmxUser"
            eval container_jmxUser=\$${container_jmxUser_var_name}
      
            container_jmxPwd_var_name="ESB_${CONTAINER_IDX}_container_jmxPassword"
            eval container_jmxPwd=\$${container_jmxPwd_var_name}

            create_all_graphs_for_one_container ${ip} "${AdminPwd}" "${CONTAINER_NAME}" "${container_ip}" "${container_jmxPort}" "${container_jmxUser}" "${container_jmxPwd}"
            update_graphs_of_all_other_containers "${CONTAINER_NAME}" "${container_ip}"
         else
            # TODO: A Petals container previously declared in Cacti was started, should we recreate all inforamtion at Cacti level ?
            # TODO: If the @IP has changed we must update it
            echo "A Petals container previously declared in Cacti was started"
         fi
      else
         # A Petals container was stopped
         # TODO: Should we remove all information at Cacti level ?
         echo "A Petals container was stopped"
      fi
   else
      echo "Configuration change not initiated by a Petals container"
   fi

   exit $?
else
   # A configuration change occurs but not in the Roboconf application "ESB" 
   exit 0
fi
