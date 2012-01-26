require 'curb'
require 'nokogiri'

Puppet::Parser::Functions::newfunction(:rhevm_validate_export_type,
                                       :type => :rvalue,
                                       :doc => <<ENDDOC
Validates that the RHEV nfs export path is on a storage domain
where type equals to export. Otherwise pushes to RHEV will fail.
It also validates that the storage domain is in the data center
of this RHEV's deltacloud provider.
ENDDOC
) do |args|

  curl = Curl::Easy.new
  curl.url = "#{args[0]}/datacenters/#{args[1]}/storagedomains"
  curl.username = args[2]
  curl.password = args[3]
  curl.http_get
  result_body = curl.body_str.to_s

  storagedomains  = Nokogiri::XML(result_body)
  found = storagedomains.xpath("/storage_domains/storage_domain[type=\"export\"] and /storage_domains/storage_domain/storage[path=\"#{args[4]}\"]")

  if found == false
    raise Puppet::ParseError, "RHEV validation error: could not find path #{args[4]} in data center #{args[1]} in a storage domain where type = \"export\""
  end

  found
end
