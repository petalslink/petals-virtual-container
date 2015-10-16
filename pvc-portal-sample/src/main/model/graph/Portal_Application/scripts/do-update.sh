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

env

sed -ie "s/\(vacation.service.url: \).*$/\1http:\/\/${ESB_0_lb_ip}:${ESB_0_lb_port}\/petals\/services\/vacationService/" /var/lib/tomcat8/webapps/${applicationDir}/WEB-INF/classes/application.properties && \
sed -ie "s/\(activiti.service.process.url: \).*$/\1http:\/\/${ESB_0_lb_ip}:${ESB_0_lb_port}\/petals\/services\/processInstancesService/" /var/lib/tomcat8/webapps/${applicationDir}/WEB-INF/classes/application.properties && \
sed -ie "s/\(activiti.service.task.url: \).*$/\1http:\/\/${ESB_0_lb_ip}:${ESB_0_lb_port}\/petals\/services\/taskService/" /var/lib/tomcat8/webapps/${applicationDir}/WEB-INF/classes/application.properties

exit $?
