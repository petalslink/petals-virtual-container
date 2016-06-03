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
# along with this program/library; If not, see http://directory.fsf.org/wiki/License:BSD_3Clause/
# for the New BSD License (3-clause license).
#
#############################################################################


env

# MySQL prompts for a root password twice during MySQL package installation
# (2 steps : "root_password" and "root_password_again").

# MySQL is not automatically started when installed whith APT, so it is not required to stop it here.

apt-get update && \
echo "mysql-server mysql-server/root_password password ${MySQLRootPwd}" | debconf-set-selections && \
echo "mysql-server mysql-server/root_password_again password ${MySQLRootPwd}" | debconf-set-selections && \
apt-get -y install mysql-server
exit $?
