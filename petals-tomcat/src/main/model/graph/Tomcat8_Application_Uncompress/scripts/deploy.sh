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

unzip ${ROBOCONF_FILES_DIR}/${applicationFile} -d /var/lib/tomcat8/webapps/${applicationDir}

# Wait 10s to have the web app started
sleep 10

exit $?
