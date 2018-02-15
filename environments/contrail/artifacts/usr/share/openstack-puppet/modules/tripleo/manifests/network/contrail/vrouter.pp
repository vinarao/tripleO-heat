# Copyright 2016 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: tripleo::profile::base::neutron::opencontrail::vrouter
#
# Opencontrail profile to run the contrail vrouter
#
# === Parameters
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')
#
class tripleo::network::contrail::vrouter (
  $step               = hiera('step'),
  $admin_password     = hiera('contrail::admin_password'),
  $admin_tenant_name  = hiera('contrail::admin_tenant_name'),
  $admin_token        = hiera('contrail::admin_token'),
  $admin_user         = hiera('contrail::admin_user'),
  $api_port           = hiera('contrail::api_port'),
  $api_server         = hiera('internal_api_virtual_ip'),
  $auth_host          = hiera('contrail::auth_host'),
  $auth_port          = hiera('contrail::auth_port'),
  $auth_port_ssl      = hiera('contrail::auth_port_ssl'),
  $auth_protocol      = hiera('contrail::auth_protocol'),
  $ca_file            = hiera('contrail::service_certificate',false),
  $cert_file          = hiera('contrail::service_certificate',false),
  $cpu_mode           = hiera('contrail::vrouter::cpu_mode',false),
  $cpu_model          = hiera('contrail::vrouter::cpu_model',false),
  $control_server     = hiera('contrail_control_node_ips'),
  $disc_server_ip     = hiera('internal_api_virtual_ip'),
  $disc_server_port   = hiera('contrail::disc_server_port'),
  $gateway            = hiera('contrail::vrouter::gateway'),
  $host_ip            = hiera('contrail::vrouter::host_ip'),
  $insecure           = hiera('contrail::insecure'),
  $memcached_servers  = hiera('contrail::memcached_server'),
  $metadata_secret    = hiera('contrail::vrouter::metadata_proxy_shared_secret'),
  $netmask            = hiera('contrail::vrouter::netmask'),
  $physical_interface = hiera('contrail::vrouter::physical_interface'),
  $public_vip         = hiera('public_virtual_ip'),
  $is_tsn             = hiera('contrail::vrouter::is_tsn',false),
) {
    
    $cidr = netmask_to_cidr($netmask)
    notify { 'cidr':
      message => $cidr,
    }
    $macaddress = inline_template("<%= scope.lookupvar('::macaddress_${physical_interface}') -%>")
    #include ::contrail::vrouter
    # NOTE: it's not possible to use this class without a functional
    # contrail controller up and running
    $control_server_list = join($control_server, ' ')
    if $auth_protocol == 'https' {
      $keystone_config = {
        'KEYSTONE' => {
          'admin_password'    => $admin_password,
          'admin_tenant_name' => $admin_tenant_name,
          'admin_token'       => $admin_token,
          'admin_user'        => $admin_user,
          'auth_host'         => $auth_host,
          'auth_port'         => $auth_port_ssl,
          'auth_protocol'     => $auth_protocol,
          'insecure'          => $insecure,
          'memcached_servers' => $memcached_servers,
          'certfile'          => $cert_file,
          'cafile'            => $ca_file,
        },
      }
      $vnc_api_lib_config = {
        'auth' => {
          'AUTHN_SERVER'   => $public_vip,
          'AUTHN_PORT'     => $auth_port_ssl,
          'AUTHN_PROTOCOL' => $auth_protocol,
          'certfile'       => $cert_file,
          'cafile'         => $ca_file,
        },
      }
    } else {
    $keystone_config = {
        'KEYSTONE' => {
          'admin_password'    => $admin_password,
          'admin_tenant_name' => $admin_tenant_name,
          'admin_token'       => $admin_token,
          'admin_user'        => $admin_user,
          'auth_host'         => $auth_host,
          'auth_port'         => $auth_port,
          'auth_protocol'     => $auth_protocol,
          'insecure'          => $insecure,
          'memcached_servers' => $memcached_servers,
        },
      }
      $vnc_api_lib_config = {
        'auth' => {
          'AUTHN_SERVER' => $public_vip,
        },
      }
    }
    if $is_tsn {
      $vrouter_agent_config = {
        'DEBUG'  => {
          'agent_mode' => 'tsn',
        },
        'CONTROL-NODE'  => {
          'server' => $control_server_list,
        },
        'VIRTUAL-HOST-INTERFACE'  => {
          'compute_node_address' => $host_ip,
          'gateway'              => $gateway,
          'ip'                   => "${host_ip}/${cidr}",
          'name'                 => "vhost0",
          'physical_interface'   => $physical_interface,
        },
        'METADATA' => {
          'metadata_proxy_secret' => $metadata_secret,
        },
        'DISCOVERY' => {
          'server' => $disc_server_ip,
          'port'   => $disc_server_port,
        },
      }
    } else {
      $vrouter_agent_config = {
        'CONTROL-NODE'  => {
          'server' => $control_server_list,
        },
        'VIRTUAL-HOST-INTERFACE'  => {
          'compute_node_address' => $host_ip,
          'gateway'              => $gateway,
          'ip'                   => "${host_ip}/${cidr}",
          'name'                 => "vhost0",
          'physical_interface'   => $physical_interface,
        },
        'METADATA' => {
          'metadata_proxy_secret' => $metadata_secret,
        },
        'DISCOVERY' => {
          'server' => $disc_server_ip,
          'port'   => $disc_server_port,
        },
      }
    }
    class {'::contrail::vrouter':
      cpu_mode                   => $cpu_mode,
      cpu_model                  => $cpu_model,
      discovery_ip               => $disc_server_ip,
      gateway                    => $gateway,
      host_ip                    => $host_ip,
      is_tsn                     => $is_tsn,
      macaddr                    => $macaddress,
      mask                       => $cidr,
      netmask                    => $netmask,
      physical_interface         => $physical_interface,
      vhost_ip                   => $host_ip,
      keystone_config            => $keystone_config,
      vrouter_agent_config       => $vrouter_agent_config,
      vrouter_nodemgr_config       => {
        'DISCOVERY' => {
          'server' => $disc_server_ip,
          'port'   => $disc_server_port,
        },
      },
      vnc_api_lib_config    => $vnc_api_lib_config,
    }
  if $step >= 5 {
    class {'::contrail::vrouter::provision_vrouter':
      api_address                => $api_server,
      api_port                   => $api_port,
      host_ip                    => $host_ip,
      node_name                  => $::hostname,
      keystone_admin_user        => $admin_user,
      keystone_admin_password    => $admin_password,
      keystone_admin_tenant_name => $admin_tenant_name,
      is_tsn                     => $is_tsn,
    }
  }
}
