define postgres::user($ensure='created', $password="", $roles=""){
  case $ensure {
    'created': {
      exec{"create_${name}_postgres_user":
             unless  => "/usr/bin/test `/usr/bin/su postgres -c \"psql postgres postgres -P tuples_only -c \\\"select count(*) from pg_user where usename='${name}';\\\"\"` = \"1\"",
             command => "/usr/bin/su postgres -c \"/usr/bin/psql postgres postgres -c \
                         \\\"CREATE USER ${name} WITH PASSWORD '${password}' ${roles}\\\"\""}}
    'dropped': {
      exec{"drop_${name}_postgres_user":
             onlyif  => "/usr/bin/test `/usr/bin/su postgres -c \"psql postgres postgres -P tuples_only -c \\\"select count(*) from pg_user where usename='${name}';\\\"\"` = \"1\"",
             command => "/usr/bin/su postgres -c \"/usr/bin/psql postgres postgres -c \
                         \\\"DROP USER ${name}\\\"\""}}
  }
}
