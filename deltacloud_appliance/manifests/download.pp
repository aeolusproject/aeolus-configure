# Download one or more files, requires wget
define download(
  $source="",
  $cwd="",
  $mode="") {

  exec { "download_${name}":
         command => "/usr/bin/wget ${source}",
         cwd => $cwd,
         creates => "${cwd}/${name}",
         require => Package[wget] }
  exec { "chmod_${name}":
         command => "/bin/chmod ${mode} ${cwd}/${name}",
         require => Exec["download_${name}"] }
}

package{wget: ensure => 'installed' }
