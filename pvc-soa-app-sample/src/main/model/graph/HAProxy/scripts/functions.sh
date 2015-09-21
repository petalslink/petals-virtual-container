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


#
# Generates the HAProxy configuration
#
# Usage:
#   generate_configuration <haProxyInHttpPort>
#
# where:
#   <haProxyInHttpPort> is the incomming HTTP port,
#   <haProxyStatsHttpPort> is the HTTP port on which webapp stats is reachable.
#
# required environment variables:
#   - PetalsBCSoap_size: Petals BC Soap instance number,
#   - PetalsBCSoap_x_ip: IP address of the Petals BC Soap instance "x",
#   - PetalsBCSoap_x_httpPort: listening port of the Petals BC Soap instance "x".
#
# Returns:
#   0: The configuration generation is successfully attached,
#   1: An error occurs.
#
# Note:
#   The HAProxy configuration is expected in the directory /etc/haproxy/haproxy.cfg
#
generate_configuration()
{
   haProxyInHttpPort=$1
   haProxyStatsHttpPort=$2
   
   cat > /etc/haproxy/haproxy.cfg << EOF
global
        log /dev/log    local0
        log /dev/log    local1 notice
        chroot /var/lib/haproxy
        stats socket /run/haproxy/admin.sock mode 660 level admin
        stats timeout 30s
        user haproxy
        group haproxy
        daemon

        # Default SSL material locations
        ca-base /etc/ssl/certs
        crt-base /etc/ssl/private

        # Default ciphers to use on SSL-enabled listening sockets.
        # For more information, see ciphers(1SSL).
        ssl-default-bind-ciphers kEECDH+aRSA+AES:kRSA+AES:+AES256:RC4-SHA:!kEDH:!LOW:!EXP:!MD5:!aNULL:!eNULL
        ssl-default-bind-options no-sslv3

defaults
        log     global
        mode    http
        option  httplog
        option  dontlognull
        timeout connect 5000
        timeout client  50000
        timeout server  50000
   
        errorfile 400 /etc/haproxy/errors/400.http
        errorfile 403 /etc/haproxy/errors/403.http
        errorfile 408 /etc/haproxy/errors/408.http
        errorfile 500 /etc/haproxy/errors/500.http
        errorfile 502 /etc/haproxy/errors/502.http
        errorfile 503 /etc/haproxy/errors/503.http
        errorfile 504 /etc/haproxy/errors/504.http

listen  stats   *:${haProxyStatsHttpPort}
        mode            http
        maxconn 10

        stats enable
        #stats hide-version
        stats refresh 30s
        stats show-node
        #stats auth admin:password
        stats uri  /haproxy?stats

frontend http-in
        bind *:${haProxyInHttpPort}
        default_backend servers

backend servers
EOF

if [ -z "$PetalsBCSoap_size" ]
then
   i=0
else
   i=$PetalsBCSoap_size
fi
while [ $i -gt 0 ]
do
   i=`expr $i - 1`
   
   remote_port_var_name="PetalsBCSoap_${i}_httpPort"
   eval remote_port=\$${remote_port_var_name}
   
   remote_ip_var_name="PetalsBCSoap_${i}_ip"
   eval remote_ip=\$${remote_ip_var_name}
   
   cat >> /etc/haproxy/haproxy.cfg << EOF
        server server${i} ${remote_ip}:${remote_port} maxconn 32   
EOF
done
}
