#!/usr/bin/ruby
# setup repositories, download/install aeolus, run interactive config, bring up wui
# must be run as the super user
# TODO other distro support

require 'optparse'

Signal.trap("INT") do
  puts ""
  exit 1
end

colors = {:reset   => "\e[0m",
          :bold    => "\e[1m",
          :black   => "\e[30m",
          :red     => "\e[31m",
          :blue    => "\e[34m",
          :green   => "\e[32m"}

puts "#{colors[:bold]}To The Cloud!....#{colors[:reset]}"

options = {:deploy  => false,
           :migrate => false,
           :scale   => false}

optparse = OptionParser.new do |opts|
  opts.banner = "#{colors[:bold]}Usage: cloud.rb [options]"
  opts.on("-d", "--deploy",  "Deploy new instances to the cloud")                             { options[:deploy] = true }
  opts.on("-m", "--migrate", "Migrate existing instances from one cloud provider to another") { options[:migrate] = true }
  opts.on("-s", "--scale",   "Scale existing instances accross cloud providers")              { options[:scale] = true }
  opts.on("-h", "--help",    'Display this message' ) { puts opts ; exit 0 }
end

optparse.parse!

options[:deploy] = true unless options.values.include? true

####################
puts "#{colors[:blue]}setting up repositories..."

FEDORA="14"

REPOS={:testing      => "http://repos.fedorapeople.org/repos/aeolus/conductor/testing/fedora-$releasever/$basearch/",
       :expiremental => "http://yum.morsi.org/aeolus/",
       :deltacloud   => "http://devel.mifo.sk/deltacloud/current/$basearch"}

File.open("/etc/yum.repos.d/aeolus.repo", "w"){ |f|
  REPOS.each { |n,r|
    repo = "[aeolus_#{n}]\n" +
           "name=aeolus_#{n}\n"   +
           "baseurl=#{r}\n"  +
           "enabled=1\n"     +
           "skip_if_unavailable=1\n" +
           "gpgcheck=0\n"
    f.write repo
    puts "Created aeolus_#{n}"
  }
}

puts "#{colors[:green]}Done\n\n"

#####################
puts "#{colors[:blue]}installing packages............"

IO.popen("yum install deltacloud-core-all aeolus-all -y") do |p|
  while l = p.gets do
    puts l
  end
end

puts "#{colors[:green]}Done\n\n"

#####################
puts "#{colors[:blue]}launching configure............"

# just fork/exec here to handle stdin
fork{
  exec "/usr/sbin/aeolus-configure -i #{options.collect { |o| "--#{o}" }.join(" ")}"
}
Process.wait

puts "#{colors[:green]}Done\n\n"

# TODO open up web browser to conductor

puts "#{colors[:reset]}"
