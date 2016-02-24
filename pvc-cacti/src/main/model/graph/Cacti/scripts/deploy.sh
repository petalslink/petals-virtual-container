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

##############################################################################################################################
# Deployment script inspired by http://forums.cacti.net/download/file.php?id=22710&sid=3533b205e05d0561eac738b481579ee4
##############################################################################################################################

COOKIE_FILE="/tmp/cacti-post-install-settings.cookie"

env

# It is not needed to reload APT indexes, already done when deploying Apache HTTPD

echo "cacti cacti/webserver select apache2" | debconf-set-selections && \
echo "cacti cacti/mysql/admin-pass password ${MySQL_0_MySQLRootPwd}" | debconf-set-selections && \
echo "cacti cacti/db/app-user string ${Cacti_DB_0_MySQLCactiUser}" | debconf-set-selections && \
echo "cacti cacti/mysql/app-pass password ${Cacti_DB_0_MySQLCactiPwd}" | debconf-set-selections && \
echo "cacti cacti/dbconfig-install boolean true" | debconf-set-selections && \
apt-get -y install cacti && \
service apache2 reload
if [ $? -eq 0 ]
   then
      #######################################################################################################
      # Caution, with 'curl' don't use "--request [POST|GET]" in combination with "-L" because POST requests
      # are not automatically switches in GET according to the HTTP return code.
      #######################################################################################################
      rm -f ${COOKIE_FILE}

      CSRF_MAGIC=`curl -L --request GET "http://${ip}/cacti" -c ${COOKIE_FILE} | sed -n 's/.*name=.__csrf_magic.\s\+value="\(sid:[^"]*\).*/\1/p'` && \ 
      curl -L "http://${ip}/cacti/install/index.php" --referer "http://${ip}/cacti/install/" -b ${COOKIE_FILE} -c ${COOKIE_FILE} \
           --data "__csrf_magic=${CSRF_MAGIC}" \
           --data "step=1" && \
      curl -L "http://${ip}/cacti/install/index.php" --referer "http://${ip}/cacti/install/index.php" -b ${COOKIE_FILE} -c ${COOKIE_FILE} \
           --data "__csrf_magic=${CSRF_MAGIC}" \
           --data "step=2" \
           --data "install_type=1" && \ 
      CSRF_MAGIC=`curl -L "http://${ip}/cacti/install/index.php" --referer "http://${ip}/cacti/install/index.php" -b ${COOKIE_FILE} -c ${COOKIE_FILE}  \
           --data "__csrf_magic=${CSRF_MAGIC}" \
           --data "step=3" \
           --data-urlencode "path_rrdtool=/usr/bin/rrdtool" \
           --data-urlencode "path_php_binary=/usr/bin/php" \
           --data-urlencode "path_snmpwalk=/usr/bin/snmpwalk" \
           --data-urlencode "path_snmpget=/usr/bin/snmpget" \
           --data-urlencode "path_snmpbulkwalk=/usr/bin/snmpbulkwalk" \
           --data-urlencode "path_snmpgetnext=/usr/bin/snmpgetnext" \
           --data-urlencode "path_cactilog=/var/log/cacti/cacti.log" \
           --data-urlencode "snmp_version=net-snmp" \
           --data-urlencode "rrdtool_version=rrd-1.4.x" | sed -n 's/.*name=.__csrf_magic.\s\+value="\(sid:[^"]*\).*/\1/p'` && \
      curl -L "http://${ip}/cacti/index.php" --referer "http://${ip}/cacti/index.php" -b ${COOKIE_FILE} -c ${COOKIE_FILE} \
           --data "__csrf_magic=${CSRF_MAGIC}" \
           --data "action=login" \
           --data "login_username=admin" \
           --data "login_password=admin" && \
      curl -L "http://${ip}/cacti/auth_changepassword.php" --referer "http://${ip}/cacti/auth_changepassword.php?ref=http://${ip}/cacti/index.php" -b ${COOKIE_FILE} -c ${COOKIE_FILE} \
           --data "__csrf_magic=${CSRF_MAGIC}" \
           --data "action=changepassword" \
           --data-urlencode "password=${AdminPwd}" \
           --data-urlencode "confirm=${AdminPwd}" \
           --data-urlencode "ref=http://${ip}/cacti/index.php"
      exit $? 
   else
      exit 1
   fi


exit $?

