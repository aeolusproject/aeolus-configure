# Some convenience routines for system time manipulation

# Sync system time via ntp
define time::sync(){
  exec{"sync_time":
    command  => "/usr/sbin/ntpdate pool.ntp.org"
  }
}
