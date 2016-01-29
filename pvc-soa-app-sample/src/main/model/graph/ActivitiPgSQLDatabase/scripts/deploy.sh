#!/bin/sh -x
#
# Copyright (c) 2015-2016 Linagora
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

#
# Create the Activiti database
#
echo "host	${databaseName}	${databaseUser}	samenet	md5" >> /etc/postgresql/9.3/main/pg_hba.conf && \
pg_ctlcluster 9.3 main reload && \
sudo -u postgres psql --echo-all -c "CREATE USER ${databaseUser} WITH CREATEDB PASSWORD '${databasePwd}'" && \
sudo -u postgres createdb --echo --owner=${databaseUser} ${databaseName} && \
sudo -u postgres psql --echo-all -c "GRANT CONNECT ON DATABASE ${databaseName} to ${databaseUser}" && \
sudo -u postgres psql --echo-all -d ${databaseName} -c "GRANT USAGE ON SCHEMA public to ${databaseUser}" && \
sudo -u postgres psql --echo-all -d ${databaseName} -f ${ROBOCONF_FILES_DIR}/org/activiti/db/create/activiti.postgres.create.engine.sql && \
sudo -u postgres psql --echo-all -d ${databaseName} -f ${ROBOCONF_FILES_DIR}/org/activiti/db/create/activiti.postgres.create.history.sql && \
sudo -u postgres psql --echo-all -d ${databaseName} -c "ALTER TABLE ACT_GE_BYTEARRAY ALTER COLUMN NAME_ TYPE VARCHAR(512)" && \
sudo -u postgres psql --echo-all -d ${databaseName} -c "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ${databaseUser}" && \
sudo -u postgres psql --echo-all -d ${databaseName} -c "GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO ${databaseUser}"

exit $?

