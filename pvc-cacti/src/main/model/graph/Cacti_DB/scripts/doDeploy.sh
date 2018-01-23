#!/bin/sh -x
#
# Copyright (c) 2016-2018 Linagora
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

##############################################################################################################################
# Deployment script inspired by http://forums.cacti.net/download/file.php?id=22710&sid=3533b205e05d0561eac738b481579ee4
##############################################################################################################################

env

mysqladmin -u root -p${MySQL_0_MySQLRootPwd} create ${MySQLCactiDB} && \
echo "GRANT ALL ON cacti.* TO ${MySQLCactiUser}@localhost IDENTIFIED BY '${MySQLCactiPwd}';" | mysql -u root -p${MySQL_0_MySQLRootPwd} mysql

exit $?
