#!/usr/bin/ruby

#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# Connect to the configured image warehouse, query and delete all
# existing objects via the REST API

require 'rubygems'
require 'oauth'
require 'json'
require 'uri'
require 'facter'

JSON_PLZ = {'Accept' => 'application/json'}

def usage
  puts <<EOS
Usage: #{$0} [iwhd-url] (example: http://localhost:9090)
EOS
  exit 1
end

usage unless ARGV.size == 1

Facter.search('/usr/share/aeolus-configure/modules/aeolus/lib/facter')
Facter.loadfacts

consumer = OAuth::Consumer.new(
  Facter.iwhd_oauth_user,
  Facter.iwhd_oauth_password,
  :site => ARGV[0]
)

token = OAuth::AccessToken.new(consumer)

providers = JSON::parse(token.get('/', JSON_PLZ).body)['providers']
buckets = providers.map{|x| x['link']}.select{|x| x !~ /(_new|_providers)/}

deleted_objects = 0
buckets.each do |bucket|
  path = URI.parse(bucket).path
  objects = JSON::parse(token.get(path, JSON_PLZ).body)

  objects.each do |o|
    obj_path = "#{path}/#{o['key']}"
    token.delete(obj_path, JSON_PLZ)
    deleted_objects += 1
  end
end

puts "Objects deleted: #{deleted_objects}"
