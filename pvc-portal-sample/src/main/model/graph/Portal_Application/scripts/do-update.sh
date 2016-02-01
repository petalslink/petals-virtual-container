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

env

sed -ie "s/\(vacation.service.url: \).*$/\1http:\/\/${ESB_0_lb_ip}:${ESB_0_lb_port}\/petals\/services\/vacationService/" /var/lib/tomcat8/webapps/${applicationDir}/WEB-INF/classes/application.properties && \
sed -ie "s/\(activiti.service.process.url: \).*$/\1http:\/\/${ESB_0_lb_ip}:${ESB_0_lb_port}\/petals\/services\/processInstancesService/" /var/lib/tomcat8/webapps/${applicationDir}/WEB-INF/classes/application.properties && \
sed -ie "s/\(activiti.service.task.url: \).*$/\1http:\/\/${ESB_0_lb_ip}:${ESB_0_lb_port}\/petals\/services\/taskService/" /var/lib/tomcat8/webapps/${applicationDir}/WEB-INF/classes/application.properties
