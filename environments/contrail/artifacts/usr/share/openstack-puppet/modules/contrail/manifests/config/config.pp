# == Class: contrail::config::config
#
# Configure the config service
#
# === Parameters:
#
# [*api_config*]
#   (optional) Hash of parameters for /etc/contrail/contrail-api.conf
#   Defaults to {}
#
# [*alarm_gen_config*]
#   (optional) Hash of parameters for /etc/contrail/contrail-alarm-gen.conf
#   Defaults to {}
#
# [*config_nodemgr_config*]
#   (optional) Hash of parameters for /etc/contrail/contrail-config-nodemgr.conf
#   Defaults to {}
#
# [*discovery_config*]
#   (optional) Hash of parameters for /etc/contrail/contrail-discovery.conf
#   Defaults to {}
#
# [*schema_config*]
#   (optional) Hash of parameters for /etc/contrail/contrail-schema.conf
#   Defaults to {}
#
# [*device_manager_config*]
#   (optional) Hash of parameters for /etc/contrail/contrail-device-managerr.conf
#   Defaults to {}
#
# [*svc_monitor_config*]
#   (optional) Hash of parameters for /etc/contrail/contrail-svc-monitor.conf
#   Defaults to {}
#
# [*basicauthusers_property*]
#   (optional) List of pairs of ifmap users. Example: user1:password1
#   Defaults to []
#
class contrail::config::config (
  $alarm_gen_config        = {},
  $api_config              = {},
  $basicauthusers_property = [],
  $config_nodemgr_config   = {},
  $device_manager_config   = {},
  $discovery_config        = {},
  $keystone_config         = {},
  $schema_config           = {},
  $svc_monitor_config      = {},
  $vnc_api_lib_config      = {},
) {

  file { '/etc/contrail/contrail-keystone-auth.conf':
    ensure => file,
  }
  validate_hash($api_config)
  validate_hash($alarm_gen_config)
  validate_hash($config_nodemgr_config)
  validate_hash($device_manager_config)
  validate_hash($discovery_config)
  validate_hash($keystone_config)
  validate_hash($schema_config)
  validate_hash($svc_monitor_config)
  validate_hash($vnc_api_lib_config)

  validate_array($basicauthusers_property)

  $contrail_api_config = { 'path' => '/etc/contrail/contrail-api.conf' }
  $contrail_alarm_gen_config = { 'path' => '/etc/contrail/contrail-alarm-gen.conf' }
  $contrail_config_nodemgr_config = { 'path' => '/etc/contrail/contrail-config-nodemgr.conf' }
  $contrail_device_manager_config = { 'path' => '/etc/contrail/contrail-device-manager.conf' }
  $contrail_discovery_config = { 'path' => '/etc/contrail/contrail-discovery.conf' }
  $contrail_keystone_config = { 'path' => '/etc/contrail/contrail-keystone-auth.conf' }
  $contrail_schema_config = { 'path' => '/etc/contrail/contrail-schema.conf' }
  $contrail_svc_monitor_config = { 'path' => '/etc/contrail/contrail-svc-monitor.conf' }
  $contrail_vnc_api_lib_config = { 'path' => '/etc/contrail/vnc_api_lib.ini' }

  create_ini_settings($api_config, $contrail_api_config)
  create_ini_settings($alarm_gen_config, $contrail_alarm_gen_config)
  create_ini_settings($config_nodemgr_config, $contrail_config_nodemgr_config)
  create_ini_settings($device_manager_config, $contrail_device_manager_config)
  create_ini_settings($discovery_config, $contrail_discovery_config)
  create_ini_settings($keystone_config, $contrail_keystone_config)
  create_ini_settings($schema_config, $contrail_schema_config)
  create_ini_settings($svc_monitor_config, $contrail_svc_monitor_config)
  create_ini_settings($vnc_api_lib_config, $contrail_vnc_api_lib_config)

  file { '/etc/ifmap-server/basicauthusers.properties' :
    ensure  => file,
    content => template('contrail/config/basicauthusers.properties.erb'),
  }

  file {'/etc/ifmap-server/log4j.properties' :
    ensure  => file,
    content => template('contrail/config/log4j.properties.erb'),
  }

}
