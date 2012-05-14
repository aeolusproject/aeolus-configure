define aeolus::rhevm::validate($rhevm_rest_api_url,$rhevm_data_center,$rhevm_username,$rhevm_password,$rhevm_nfs_export){
  $result = rhevm_validate_export_type($rhevm_rest_api_url,$rhevm_data_center,$rhevm_username,$rhevm_password,$rhevm_nfs_export)
  notify {"${name}":
    message => "the RHEV NFS export is on the correct storage domain and has type 'export' => ${result}"
  }
}
