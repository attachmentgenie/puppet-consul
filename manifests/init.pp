#
# @summary Installs, configures and manages consul
#
# @param acls Hash of consul_acl resources to create.
# @param tokens Hash of consul_token resources to create.
# @param policies Hash of consul_policy resources to create.
# @param acl_api_hostname Global hostname of ACL API, will be merged with consul_token resources
# @param acl_api_protocol Global protocl of ACL API, will be merged with consul_token resources
# @param acl_api_port Global port of ACL API, will be merged with consul_token resources
# @param acl_api_tries Global max. tries of ACL API, will be merged with consul_token resources
# @param acl_api_token Global token of ACL API, will be merged with consul_token resources
# @param arch Architecture of consul binary to download
# @param archive_path Path used when installing consul via the url
# @param bin_dir Directory to create the symlink to the consul binary in.
# @param binary_group The group that the file belongs to.
# @param binary_mode Permissions mode for the file.
# @param binary_name The binary name file.
# @param binary_owner The user that owns the file.
# @param checks Hash of consul::check resources to create.
# @param config_defaults Configuration defaults hash. Gets merged with config_hash.
# @param config_dir Directory to place consul configuration files in.
# @param config_name Name of the consul configuration file.
# @param config_hash Use this to populate the JSON config file for consul.
# @param config_mode Use this to set the JSON config file mode for consul.
# @param config_owner The user that owns the config_dir directory and its files.
# @param data_dir_mode Use this to set the data_dir directory mode for consul.
# @param docker_image Only valid when the install_method == docker. Defaults to `consul`.
# @param download_extension The extension of the archive file containing the consul binary to download.
# @param download_url Fully qualified url, puppet uri or absolute path to the location of the archive file containing the consul binary.
# @param download_url_base Base url to the location of the archive file containing the consul binary.
# @param extra_groups Extra groups to add the consul system user to.
# @param extra_options Extra arguments to be passed to the consul agent
# @param group Name of the group that should own the consul configuration files.
# @param init_style
#   What style of init system your system uses. Set to 'unmanaged' to disable
#   managing init system files for the consul service entirely.
#   This is ignored when install_method == 'docker'
# @param install_method
#   Valid strings: `docker`  - install via docker container
#                  `package` - install via system package
#                  `url`     - download and extract from a url. Defaults to `url`.
#                  `none`    - disable install.
# @param join_wan The wan to join on service start (e.g. 'wan.foo.com'). Defaults to undef (i.e. won't join a wan).
# @param manage_group Whether to create/manage the group that should own the consul configuration files.
# @param manage_repo Configure the upstream HashiCorp repository. Only relevant when $consul::install_method = 'package'.
# @param manage_service Whether to manage the consul service.
# @param manage_user Whether to create/manage the user that should own consul's configuration files.
# @param manage_user_home_location
#   Whether to explicitly set the location of the consul user's home directory when this modules
#   manages the creation of the user (aka `manage_user = true`). If the consul user already exists
#   and this is enabled, puppet tries to change the consul user's home to the new location. This
#   will cause the puppet run to fail if the consul service is currently running.
# @param manage_data_dir Whether to manage the consul storage data directory.
# @param os OS component in the name of the archive file containing the consul binary.
# @param package_ensure Only valid when the install_method == package. Defaults to `latest`.
# @param package_name Only valid when the install_method == package. Defaults to `consul`.
# @param pretty_config Generates a human readable JSON config file. Defaults to `false`.
# @param pretty_config_indent Toggle indentation for human readable JSON file. Defaults to `4`.
# @param proxy_server Specify a proxy server, with port number if needed. ie: https://example.com:8080.
# @param purge_config_dir Purge config files no longer generated by Puppet
# @param restart_on_change
#   Determines whether to restart consul agent on $config_hash changes.
#   This will not affect reloads when service, check or watch configs change.
# @param service_enable Whether to enable the consul service to start at boot.
# @param service_ensure Whether the consul service should be running or not.
# @param services Hash of consul::service resources to create.
# @param user Name of the user that should own the consul configuration files.
# @param version Specify version of consul binary to download.
# @param watches Hash of consul::watch resources to create.
# @param shell The shell for the consul user. Defaults to something that prohibits login, like /usr/sbin/nologin
# @param enable_beta_ui
#   consul 1.1.0 introduced a new UI, which is currently (2018-05-12) in beta status.
#   You can enable it by setting this variable to true. Defaults to false
# @param allow_binding_to_root_ports enables CAP_NET_BIND_SERVICE if true. This is currently only implemented on systemd nodes
# @param log_file where should the log file be located
# @param comment the comment for the consul user, will be added to /etc/passwd
# @param uid the ID for the consul user
#
# @example simple consul setup
#    class { 'consul':
#      config_hash => {
#        'datacenter'   => 'east-aws',
#        'node_name'    => $facts['fqdn'],
#        'pretty_config => true,
#        'retry-join'   => ['172.16.0.1'],
#      },
#    }
#
class consul (
  Hash                                  $acls                        = {},
  Hash[String[1], Consul::TokenStruct]  $tokens                      = {},
  Hash[String[1], Consul::PolicyStruct] $policies                    = {},
  String[1]                             $acl_api_hostname            = 'localhost',
  String[1]                             $acl_api_protocol            = 'http',
  Integer[1, 65535]                     $acl_api_port                = 8500,
  Integer[1]                            $acl_api_tries               = 3,
  String[0]                             $acl_api_token               = '', # lint:ignore:params_empty_string_assignment
  String[1]                             $arch                        = $consul::params::arch,
  Optional[Stdlib::Absolutepath]        $archive_path                = undef,
  Stdlib::Absolutepath                  $bin_dir                     = $consul::params::bin_dir,
  Optional[String[1]]                   $binary_group                = $consul::params::binary_group,
  String[1]                             $binary_mode                 = $consul::params::binary_mode,
  String[1]                             $binary_name                 = $consul::params::binary_name,
  String[1]                             $binary_owner                = $consul::params::binary_owner,
  Hash                                  $checks                      = {},
  Hash                                  $config_defaults             = $consul::params::config_defaults,
  Stdlib::Absolutepath                  $config_dir                  = $consul::params::config_dir,
  String[1]                             $config_name                 = 'config.json',
  Variant[Hash,Sensitive[Hash]]         $config_hash                 = {},
  String[1]                             $config_mode                 = '0664',
  Optional[String[1]]                   $config_owner                = undef,
  String[1]                             $data_dir_mode               = $consul::params::data_dir_mode,
  String[1]                             $docker_image                = 'consul',
  String[1]                             $download_extension          = 'zip',
  Optional[Stdlib::Filesource]          $download_url                = undef,
  String[1]                             $download_url_base           = 'https://releases.hashicorp.com/consul/',
  Array                                 $extra_groups                = [],
  Optional[String[1]]                   $extra_options               = undef,
  String[1]                             $group                       = $consul::params::group,
  Stdlib::Absolutepath                  $log_file                    = '/var/log/consul',
  String[1]                             $init_style                  = $consul::params::init_style,
  String[1]                             $install_method              = 'url',
  Optional[String[1]]                   $join_wan                    = undef,
  Boolean                               $manage_group                = $consul::params::manage_group,
  Boolean                               $manage_repo                 = $consul::params::manage_repo,
  Boolean                               $manage_service              = true,
  Boolean                               $manage_user                 = $consul::params::manage_user,
  Boolean                               $manage_user_home_location   = false,
  Boolean                               $manage_data_dir             = true,
  String[1]                             $os                          = $facts['kernel'].downcase,
  String[1]                             $package_ensure              = 'latest',
  String[1]                             $package_name                = 'consul',
  Boolean                               $pretty_config               = false,
  Integer                               $pretty_config_indent        = 4,
  Optional[Stdlib::HTTPUrl]             $proxy_server                = undef,
  Boolean                               $purge_config_dir            = true,
  Boolean                               $restart_on_change           = true,
  Boolean                               $service_enable              = true,
  Enum['stopped', 'running']            $service_ensure              = 'running',
  Hash                                  $services                    = {},
  String[1]                             $user                        = $consul::params::user,
  String[1]                             $version                     = '1.16.3',
  Hash                                  $watches                     = {},
  Optional[String[1]]                   $shell                       = $consul::params::shell,
  Boolean                               $enable_beta_ui              = false,
  Boolean                               $allow_binding_to_root_ports = false,
  Optional[String[1]]                   $comment                     = undef,
  Optional[Integer[1]]                  $uid                         = undef,
) inherits consul::params {
  $real_download_url = pick(
    $download_url,
    "${download_url_base}${version}/${package_name}_${version}_${os}_${arch}.${download_extension}",
  )

  $_config_hash = $config_hash ? {
    Sensitive => $config_hash.unwrap,
    default   => $config_hash
  }
  $config_hash_real = deep_merge($config_defaults, $config_hash)

  if $install_method == 'docker' {
    $user_real         = undef
    $group_real        = undef
    $config_owner_real = undef
    $init_style_real   = 'unmanaged'
  } else {
    $user_real         = $user
    $group_real        = $group
    if $config_owner {
      $config_owner_real = $config_owner
    } else {
      $config_owner_real = $user
    }
    $init_style_real   = $init_style
  }

  if $config_hash_real['data_dir'] {
    $data_dir = $config_hash_real['data_dir']
  } else {
    $data_dir = undef
  }

  if dig($config_hash_real,'ports','http') {
    $http_port = $config_hash_real['ports']['http']
  } else {
    $http_port = 8500
  }

  if dig($config_hash_real,'ports','https') {
    $https_port = $config_hash_real['ports']['https']
  } else {
    $https_port = Undef
  }

  if dig($config_hash_real,'addresses','http') {
    $http_addr = split($config_hash_real['addresses']['http'], ' ')[0]
  } elsif ($config_hash_real['client_addr']) {
    $http_addr = split($config_hash_real['client_addr'], ' ')[0]
  } else {
    $http_addr = '127.0.0.1'
  }

  if dig($config_hash_real,'verify_incoming') {
    $verify_incoming = $config_hash_real['verify_incoming']
  } else {
    $verify_incoming = false
  }

  if dig($config_hash_real,'cert_file') {
    $cert_file = $config_hash_real['cert_file']
  } else {
    $cert_file = Undef
  }

  if dig($config_hash_real,'key_file') {
    $key_file = $config_hash_real['key_file']
  } else {
    $key_file = Undef
  }

  if $services {
    create_resources(consul::service, $services)
  }

  if $watches {
    create_resources(consul::watch, $watches)
  }

  if $checks {
    create_resources(consul::check, $checks)
  }

  if $acls {
    create_resources(consul_acl, $acls)
  }

  contain 'consul::install'
  contain 'consul::config'
  contain 'consul::run_service'
  contain 'consul::reload_service'

  Class['consul::install']
  -> Class['consul::config']
  -> Class['consul::run_service']
  -> Class['consul::reload_service']

  if $restart_on_change {
    Class['consul::config']
    ~> Class['consul::run_service']
  }

  $global_acl_config = {
    'hostname'      => $acl_api_hostname,
    'protocol'      => $acl_api_protocol,
    'port'          => $acl_api_port,
    'api_tries'     => $acl_api_tries,
    'acl_api_token' => $acl_api_token,
  }

  $policies.each | $name, $policy_config | {
    $merges_policy_config = $global_acl_config + $policy_config
    create_resources(consul_policy, { $name => $merges_policy_config })
  }

  $tokens.each | $name, $token_config | {
    $merged_token_config = $global_acl_config + $token_config
    create_resources(consul_token, { $name => $merged_token_config })
  }
}
