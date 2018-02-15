# This class installs and configures Opencontrail Neutron Plugin.
#
# === Parameters
#
# [*api_server_ip*]
#   IP address of the API Server
#   Defaults to $::os_service_default
#
# [*api_server_port*]
#   Port of the API Server.
#   Defaults to $::os_service_default
#
# [*multi_tenancy*]
#   Whether to enable multi-tenancy
#   Default to $::os_service_default
#
# [*contrail_extensions*]
#   Array of OpenContrail extensions to be supported
#   Defaults to $::os_service_default
#   Example:
#
#     class {'neutron::plugins::opencontrail' :
#       contrail_extensions => ['ipam:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_ipam.NeutronPluginContrailIpam']
#     }
#
# [*keystone_auth_url*]
#   Url of the keystone auth server
#   Defaults to $::os_service_default
#
# [*keystone_admin_user*]
#   Admin user name
#   Defaults to $::os_service_default
#
# [*keystone_admin_tenant_name*]
#   Admin_tenant_name
#   Defaults to $::os_service_default
#
# [*keystone_admin_password*]
#   Admin password
#   Defaults to $::os_service_default
#
# [*keystone_admin_token*]
#   Admin token
#   Defaults to $::os_service_default
#
# [*package_ensure*]
#   (optional) Ensure state for package.
#   Defaults to 'present'.
#
# [*purge_config*]
#   (optional) Whether to set only the specified config options
#   in the opencontrail config.
#   Defaults to false.
#
class neutron::plugins::opencontrail (
  $api_server_ip              = $::os_service_default,
  $api_server_port            = $::os_service_default,
  $multi_tenancy              = $::os_service_default,
  $contrail_extensions        = $::os_service_default,
  $keystone_auth_host         = $::os_service_default,
  $keystone_auth_protocol     = $::os_service_default,
  $keystone_auth_port         = $::os_service_default,
  $keystone_auth_url          = $::os_service_default,
  $keystone_admin_user        = $::os_service_default,
  $keystone_admin_tenant_name = $::os_service_default,
  $keystone_admin_password    = $::os_service_default,
  $keystone_admin_token       = $::os_service_default,
  $keystone_public_vip        = $::os_service_default,
  $package_ensure             = 'present',
  $purge_config               = false,
) {

  include ::neutron::deps
  include ::neutron::params

  validate_array($contrail_extensions)

  package { 'neutron-plugin-contrail':
    ensure => $package_ensure,
    name   => $::neutron::params::opencontrail_plugin_package,
    tag    => ['neutron-package', 'openstack'],
  }
  package {'python-contrail':
    ensure => installed,
  }
  package {'contrail-heat':
    ensure => installed,
  }

  ensure_resource('file', '/etc/neutron/plugins/opencontrail', {
    ensure => directory,
    owner  => 'root',
    group  => 'neutron',
    mode   => '0640'}
  )

  if $::osfamily == 'Debian' {
    file_line { '/etc/default/neutron-server:NEUTRON_PLUGIN_CONFIG':
      path  => '/etc/default/neutron-server',
      match => '^NEUTRON_PLUGIN_CONFIG=(.*)$',
      line  => "NEUTRON_PLUGIN_CONFIG=${::neutron::params::opencontrail_config_file}",
      tag   => 'neutron-file-line',
    }
  }

  if $::osfamily == 'Redhat' {
    file { '/etc/neutron/plugin.ini':
      ensure  => link,
      target  => $::neutron::params::opencontrail_config_file,
      require => Package[$::neutron::params::opencontrail_plugin_package],
      tag     => 'neutron-config-file',
    }
  }

  resources { 'neutron_plugin_opencontrail':
    purge => $purge_config,
  }

  neutron_plugin_opencontrail {
    'APISERVER/api_server_ip':           value => $api_server_ip;
    'APISERVER/api_server_port':         value => $api_server_port;
    'APISERVER/multi_tenancy':           value => $multi_tenancy;
    'APISERVER/contrail_extensions':     value => join($contrail_extensions, ',');
    'KEYSTONE/auth_url':                 value => $keystone_auth_url;
    'KEYSTONE/admin_user' :              value => $keystone_admin_user;
    'KEYSTONE/admin_tenant_name':        value => $keystone_admin_tenant_name;
    'KEYSTONE/admin_password':           value => $keystone_admin_password, secret =>true;
    'KEYSTONE/admin_token':              value => $keystone_admin_token, secret =>true;
    'keystone_authtoken/admin_user':     value => $keystone_admin_user;
    'keystone_authtoken/admin_tenant':   value => $keystone_admin_tenant_name;
    'keystone_authtoken/admin_password': value => $keystone_admin_password, secret =>true;
    'keystone_authtoken/auth_host':      value => $keystone_public_vip;
    'keystone_authtoken/auth_protocol':  value => $keystone_auth_protocol;
    'keystone_authtoken/auth_port':      value => $keystone_auth_port;
  }

  file { '/usr/lib/heat':
    ensure => 'directory',
  } ->
  file { '/usr/lib/heat/contrail_heat':
    ensure => 'link',
    target => '/usr/lib/python2.7/site-packages/vnc_api/gen/heat',
  }
  $heat_conf_path = { 'path' => '/etc/heat/heat.conf' }
  $heat_conf = { 'clients_contrail' =>
    {
      'user'         => $keystone_admin_user,
      'password'     => $keystone_admin_password,
      'api_base_url' => '/',
      'api_server'   => $api_server_ip,
      'api_port'     => $api_server_port,
      'auth_host_ip' => $keystone_public_vip,
      'use_ssl'      => 'False',
    }
  }
  create_ini_settings($heat_conf, $heat_conf_path)
  exec { 'systemctl restart openstack-heat-engine':
    path => '/bin',
  }
}
