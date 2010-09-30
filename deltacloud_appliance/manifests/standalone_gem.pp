import "download"

file{"/var/local/gems/": ensure => 'directory' }

# Download a standalone gem and gem install it
define standalone_gem($source="", $ensure=""){
  package{$name:
          provider => 'gem',
          source   => "/var/local/gems/${name}",
          ensure   => $ensure,
          require  => Download[$name]}

  download{$name:
           source  => $source,
           cwd     => "/var/local/gems",
           mode    => 644,
           require => File["/var/local/gems/"]}
}
