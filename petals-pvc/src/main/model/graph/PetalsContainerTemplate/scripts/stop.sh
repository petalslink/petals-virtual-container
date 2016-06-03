#!/bin/sh -x
#
# Copyright (c) 2015-2016 Linagora
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

. ./functions.sh

# TODO: When stopping the PetalsContainerBoostrap instance, all containers instances are stopped. So, the topology is cleaned in the registry.
#       Restarting slave containers fails because slave containers are not known in the PVC topology.
#       Here, we should detach containers and reset their configuration when PetalsContainerBoostrap is stopped. So, on startup all will be regenerated
#       and slave containers re-attached. This can be done when https://github.com/roboconf/roboconf-platform/issues/320 will be fixed
stop_container ${ROBOCONF_INSTANCE_NAME}
exit $?
