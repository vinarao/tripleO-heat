# == Class: contrail::database
#
# Install and configure the database service
#
# === Parameters:
#
# [*package_name*]
#   (optional) Package name for database
#
class contrail::analyticsdatabase (
  $package_name = $contrail::params::database_package_name,
  $analyticsdatabase_params = $analyticsdatabase_params,
) inherits contrail::params {

  anchor {'contrail::analyticsdatabase::start': } ->
  class {'::contrail::database::install': } ->
  class {'::contrail::analyticsdatabase::config': 
    database_nodemgr_config => $analyticsdatabase_params['database_nodemgr_config'],
    cassandra_servers       => $analyticsdatabase_params['cassandra_servers'],
    cassandra_ip            => $analyticsdatabase_params['host_ip'],
    kafka_hostnames         => $analyticsdatabase_params['kafka_hostnames'],
    vnc_api_lib_config      => $analyticsdatabase_params['vnc_api_lib_config'],
    zookeeper_server_ips    => $analyticsdatabase_params['zookeeper_server_ips'],
  } ~>
  class {'::contrail::analyticsdatabase::service': }
  anchor {'contrail::analyticsdatabase::end': }
  
}
