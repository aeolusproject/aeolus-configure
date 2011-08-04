# Interactive aeolus configure installation utility.
# Prompt the user for provider account and instance values and write them
# to a new puppet config files

require 'rubygems'
require 'highline/import'

puts "Press ^C at any time to terminate"
Signal.trap("INT") do
  exit 1
end

NODE_YAML='/etc/aeolus-configure/nodes/default_custom'
PROFILE_RECIPE='/usr/share/aeolus-configure/modules/aeolus/manifests/profiles/custom.pp'


say "Select Aeolus Components to Install"
installed_component = nil
install_components  = []
while ![:None, :All].include?(installed_component)
  installed_component =
    choose do |menu|
      menu.prompt = "Install Aeolus Component: "
      menu.choice :All
      menu.choice :None
      menu.choice :"Image Factory"
      menu.choice :"Image Warehouse"
      menu.choice :"Conductor"
    end
  if installed_component == :"Image Factory"
    install_components << "- aeolus::image-factory"
  elsif installed_component == :"Image Warehouse"
    install_components << "- aeolus::iwhd"
  elsif installed_component == :"Conductor"
    install_components << "- aeolus::conductor"
  elsif installed_component == :All
    install_components << "- aeolus::conductor"  <<
                          "- aeolus::image-factory" <<
                          "- aeolus::iwhd"
  end
end

providers = []
if install_components.include? "- aeolus::conductor"
  provider_port = 3001
  profile=''
  profile_requires = []
  while agree("Add provider (y/n)? ")
    name = ask("Cloud provider label: ")
    type = choose do |menu|
      menu.prompt = "Cloud provider type: "
      menu.choice :mock
      menu.choice :ec2
      #menu.choice :rackspace
      #menu.choice :rhevm
      #menu.choice :vsphere
    end
    providers << [name,type]

    if type == :mock
      profile += "aeolus::provider{#{name}:\n" +
                 "  type     =>  'mock',\n"    +
                 "  port     =>  '#{provider_port += 1}',\n" +
                 "  require  =>  Aeolus::Conductor::Login['admin'] }\n\n" +
                 "aeolus::conductor::provider::account{#{name}:\n" +
                 "  provider =>  'mock',\n"  +
                 "  type     =>  'mock',\n"  +
                 "  username =>  'mockuser',\n" +
                 "  password =>  'mockpassword',\n" +
                 "  require  =>  Aeolus::Provider['#{name}'] }\n\n"
      profile_requires <<  "Aeolus::Provider['#{name}']" <<
                           "Aeolus::Conductor::Provider::Account['#{name}']"

    elsif type == :ec2
      endpoint            = ask("EC2 Endpoint: ")
      access_key          = ask("EC2 Access Key: ")
      secret_access_key   = ask("EC2 Secret Access Key: "){ |q| q.echo = false }
      account_id          = ask("EC2 Account ID: ")
      public_cert         = ask("EC2 Public Cert: ")
      private_key         = ask("EC2 Private Key: ")
      profile += "aeolus::provider{#{name}:\n" +
                 "  type     =>  'ec2',\n"   +
                 "  endpoint =>  '#{endpoint}',\n" +
                 "  port     =>  '#{provider_port += 1}',\n" +
                 "  require  =>  Aeolus::Conductor::Login['admin'] }\n\n" +
                 "aeolus::conductor::provider::account{#{name}:\n" +
                 "  provider =>  '#{name}',\n"  +
                 "  type     =>  'ec2',\n"  +
                 "  username =>  '#{access_key}',\n" +
                 "  password =>  '#{secret_access_key}',\n" +
                 "  account_id  =>  '#{account_id}',\n" +
                 "  x509private =>  '#{private_key}',\n" +
                 "  x509public  =>  '#{public_cert}',\n" +
                 "  require  =>  Aeolus::Provider['#{name}'] }\n\n"
      profile_requires << "Aeolus::Provider['#{name}']" <<
                          "Aeolus::Conductor::Provider::Account['#{name}']"

  #  else if type == :rackspace ...
    end
  end

  # TODO change to create image / deploy to providers (which to select)
  while agree("Deploy instance to providers (y/n)? ")
    name = ask("Instance name: ")
    providers.each { |provider|
      pname,ptype = *provider
      profile += "aeolus::image{#{pname}-#{name}:\n" +
                 "  target   =>  '#{ptype}',\n" +
                 "  template =>  'examples/custom_repo.tdl',\n" +
                 "  provider =>  '#{pname}',\n" +
                 "  require  =>  [Aeolus::Conductor::Provider::Account['#{pname}'], Aeolus::Conductor::Hwp['hwp1']] }\n\n"
      profile_requires <<  "Aeolus::Image['#{pname}-#{name}']"
    }

  #  while agree("Add yum repo? ")
  #    yum_repo          = ask("URI ")
  #  end
  #
  #  while agree("Add package? ") do
  #    package_name      = ask("Package Name ")
  #  end
  #
  #  while agree("Add file? ") do
  #    src_location      = ask("File Source ")
  #    dst_location      = ask("File Destination ")
  #  end
  #
  end
end


# create the profile
text = File.read PROFILE_RECIPE
File.open(PROFILE_RECIPE, 'w+'){|f|
  requires = profile_requires.join(',')
  requires += ", " unless requires == ""
  f << text.gsub(/#AEOLUS_SEED_DATA_REQUIRES/, requires).
            gsub(/#AEOLUS_SEED_DATA/, profile)
}

# create the node yaml
text = File.read NODE_YAML
File.open(NODE_YAML, 'w+'){|f|
  f << text.gsub(/CUSTOM_CLASSES/, install_components.join("\n"))
}
