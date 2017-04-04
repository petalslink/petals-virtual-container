#!/bin/sh -x
#
# Copyright (c) 2015-2017 Linagora
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

if [ -f ${ROBOCONF_FILES_DIR}/../scripts/do-update.sh ]
then
	. ${ROBOCONF_FILES_DIR}/../scripts/do-update.sh && \
	wget -O - http://tomcat:tomcat@localhost:8080/manager/text/reload?path=/${applicationDir} && \
	wget -O - http://tomcat:tomcat@localhost:8080/manager/text/start?path=/${applicationDir}
else
	wget -O - http://tomcat:tomcat@localhost:8080/manager/text/start?path=/${applicationDir}
fi

exit $?
