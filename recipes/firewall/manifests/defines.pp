# usage
# firewall::rule { 'rulename':
#                     chain  => "INPUT",
#                     table  => "filter",
#                     source_port => 123423,
#                     destination_port => 22,
#                     destination    => foo.com,
#                     source    => bar.com,
#                     to_ports => "443"
#                     action => ACCEPT
#                 }
define firewall::rule (
    $chain = 'INPUT',
    $table = 'filter',
    $comment = '',
    $protocol = 'tcp',
    $source_port = '',
    $destination_port = '',
    $source = '',
    $destination = '',
    $to_ports = '',
    $to_destination = '',
    $modules = [],
    $destination_range = '',
    $not_physdev_bridged = '',
    $source_range = '',
    $out_interface = '',
    $in_interface = '',
    $uid_owner = '',
    $reject_with = '',
    $log_prefix = '',
    $state = '',
    $every = '',
    $mode = '',
    $action = 'ACCEPT'
    ) {

    include firewall

    $table_path = "${firewall::firewall_dir}/${table}"
    $chain_path = "${firewall::firewall_dir}/${table}/${chain}"

    if defined(File["${chain_path}"]) {
        # do nothing
        $trash = ''
    } else {
        file { "${chain_path}":
            ensure      => directory,
            purge       => true,
            recurse     => true,
            require     => File["${table_path}"],
        }
    }

    $link_path = "$firewall::firewall_dir/${table}/${chain}/${name}"

    file { "${link_path}":
        content         => template("firewall/rule.erb"),
        notify          => Service["firewall"],
    }
}

define firewall::rule::stub () {
  file {
    "${name}.head":
      name    => "${firewall_dir}/${name}.head",
      mode    => 0700,
      source  => "puppet:///modules/firewall/chain_rules/${name}.head",
    ;
    "${name}.tail":
      name    => "${firewall_dir}/${name}.tail",
      mode    => 0700,
      source  => "puppet:///modules/firewall/chain_rules/${name}.tail",
    ;
  }
}

