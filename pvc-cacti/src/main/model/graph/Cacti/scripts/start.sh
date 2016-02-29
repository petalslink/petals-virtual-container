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

# TODO: Should we start Apache2 to start Cacti ?
# TODO: Should we start the metrics pooling ?

. ./functions.sh

create_all_graphs_for_all_containers_known()
{
   CACTI_HOSTNAME=$1
   ADMIN_PWD=$2
   
   if [ -z "${ESB_size}" ]
   then
      i=0
   else
      i=${ESB_size}
   fi
   while [ $i -gt 0 ]
   do
      i=`expr $i - 1`
      
      container_name_var_name="ESB_${i}_name"
      eval container_name_full=\$${container_name_var_name}
      container_name=`echo ${container_name_full} | cut -d'/' -f 3`
      
      container_ip_var_name="ESB_${i}_container_ip"
      eval container_ip=\$${container_ip_var_name}
      
      container_jmxPort_var_name="ESB_${i}_container_jmxPort"
      eval container_jmxPort=\$${container_jmxPort_var_name}
      
      container_jmxUser_var_name="ESB_${i}_container_jmxUser"
      eval container_jmxUser=\$${container_jmxUser_var_name}
      
      container_jmxPwd_var_name="ESB_${i}_container_jmxPassword"
      eval container_jmxPwd=\$${container_jmxPwd_var_name}
      
      create_all_graphs_for_one_container ${CACTI_HOSTNAME} "${ADMIN_PWD}" "${container_name}" "${container_ip}" "${container_jmxPort}" "${container_jmxUser}" "${container_jmxPwd}"
   done
}

env

# Start the Cacti application:
#    - Start the service 'Cron' required by the Cacti poller
#    - Create all graphs associated to all known Petals containers in dedicated graph trees
service cron start && \
create_all_graphs_for_all_containers_known ${ip} ${AdminPwd}

exit $?
