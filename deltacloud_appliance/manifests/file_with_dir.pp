# Wrapper around file, creating parent directory if it doesn't exist first
define file_with_dir($dir = "", $source = "", $mode = ""){
  file{"${dir}":
       ensure => "directory" }
  file{"${dir}/${name}":
       source  => $source,
       mode    => $mode,
       require => File[$dir]}
}
