#!/bin/sh -x

. ./env.sh

#
# Install runtime of Petals Registry
#

wget -O ${PETALS_COMMON_DEB_FILE} \
     "http://repository.ow2.org/nexus/service/local/artifact/maven/content?r=snapshots&g=${PETALS_GROUP_ID}&a=${PETALS_COMMONS_DEB_ARTIFACT_ID}&v=${PETALS_COMMONS_DEB_VERSION}&p=deb" && 
  wget -O ${PETALS_REGISTRY_DEB_FILE} \
     "http://repository.ow2.org/nexus/service/local/artifact/maven/content?r=snapshots&g=${PETALS_GROUP_ID}&a=${PETALS_REGISTRY_DEB_ARTIFACT_ID}&v=${PETALS_REGISTRY_DEB_VERSION}&p=deb" &&
  dpkg -i ${PETALS_COMMON_DEB_FILE} ${PETALS_REGISTRY_DEB_FILE}