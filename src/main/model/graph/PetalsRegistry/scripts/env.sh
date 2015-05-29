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

OW2_NEXUS_URL_BASE=http://repository.ow2.org/nexus/service/local/artifact/maven/content
PETALS_GROUP_ID=org.ow2.petals
PETALS_COMMONS_DEB_ARTIFACT_ID=petals-commons-deb
PETALS_COMMONS_DEB_VERSION=LATEST
PETALS_COMMON_DEB_FILE=/tmp/${PETALS_COMMONS_DEB_ARTIFACT_ID}-${PETALS_COMMONS_DEB_VERSION}.deb
PETALS_REGISTRY_DEB_ARTIFACT_ID=petals-registry-overlay-deb
PETALS_REGISTRY_DEB_VERSION=LATEST
PETALS_REGISTRY_DEB_FILE=/tmp/${PETALS_REGISTRY_DEB_ARTIFACT_ID}-${PETALS_REGISTRY_DEB_VERSION}.deb
