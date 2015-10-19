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

if [ -f ${ROBOCONF_FILES_DIR}/../scripts/do-update.sh ]
then
	. ${ROBOCONF_FILES_DIR}/../scripts/do-update.sh && \
	wget -O - http://tomcat:tomcat@localhost:8080/manager/text/start?path=/${applicationDir}
else
	wget -O - http://tomcat:tomcat@localhost:8080/manager/text/start?path=/${applicationDir}
fi

exit $?