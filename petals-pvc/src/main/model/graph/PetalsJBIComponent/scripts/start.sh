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

if [ "${componentType}" != "SL" ]
then
   # A shared library can not be started !!
   petals-cli -h localhost -n 7700 -u petals -p petals -c -- start-artifact -a ${componentId} -t ${componentType}
   if [ $? -eq 0 ]
   then
      return 0
   else
      return 1
   fi
else
   return 0
fi