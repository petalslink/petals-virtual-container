#!/bin/sh -x
#
# Copyright (c) 2015-2018 Linagora
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

env

if [ -z "$ESB_size" ]
then
   i=0
else
   i=$ESB_size
fi
while [ $i -gt 0 ]
do
   i=`expr $i - 1`

   esb_name_var_name="ESB_${i}_name"
   eval esb_name=\$${esb_name_var_name}

   if [ "${esb_name}" = "/HAProxy ESB VM/HAProxy ESB" ]
   then
      esb_lp_ip_var_name="ESB_${i}_lb_ip"
      eval esb_lb_ip=\$${esb_lp_ip_var_name}
      esb_lb_port_var_name="ESB_${i}_lb_port"
      eval esb_lb_port=\$${esb_lb_port_var_name}
      sed -ie "s/\(vacation.service.url: \).*$/\1http:\/\/${esb_lb_ip}:${esb_lb_port}\/petals\/services\/vacationService/" /var/lib/tomcat8/webapps/${applicationDir}/WEB-INF/classes/application.properties && \
      sed -ie "s/\(flowable.service.process.url: \).*$/\1http:\/\/${esb_lb_ip}:${esb_lb_port}\/petals\/services\/processInstancesService/" /var/lib/tomcat8/webapps/${applicationDir}/WEB-INF/classes/application.properties && \
      sed -ie "s/\(flowable.service.task.url: \).*$/\1http:\/\/${esb_lb_ip}:${esb_lb_port}\/petals\/services\/taskService/" /var/lib/tomcat8/webapps/${applicationDir}/WEB-INF/classes/application.properties
   fi
done
