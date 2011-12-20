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

require 'uri'

# A puppet resource type used to access resources on the World Wide Web
Puppet::Type.newtype(:web_request) do
    @doc = "Issue a request to a resource on the world wide web"

    private

    # Validates uris passed in
    def self.validate_uri(url)
      begin
        uri = URI.parse(url)
        raise ArgumentError, "Specified uri #{url} is not valid" if ![URI::HTTP, URI::HTTPS].include?(uri.class)
      rescue URI::InvalidURIError
        raise ArgumentError, "Specified uri #{url} is not valid"
      end
    end

    # Validates http statuses passed in
    def self.validate_http_status(status)
      status = [status] unless status.is_a?(Array)
      status.each { |stat|
        stat = stat.to_s
        unless ['100', '101', '102', '122',
                '200', '201', '202', '203', '204', '205', '206', '207', '226',
                '300', '301', '302', '303', '304', '305', '306', '307',
                '400', '401', '402', '403', '404', '405', '406', '407', '408', '409',
                '410', '411', '412', '413', '414', '415', '416', '417', '418',
                '422', '423', '424', '425', '426', '444', '449', '450', '499',
                '500', '501', '502', '503', '504', '505', '506', '507', '508', ' 509', '510'
                ].include?(stat)
          raise ArgumentError, "Invalid http status code #{stat} specified"
        end
      }
    end

    # Convert singular params into arrays of strings
    def self.munge_array_params(value)
      value = [value] unless value.is_a?(Array)
      value = value.collect { |val| val.to_s }
      value
    end

    newparam :name

    newproperty(:get) do
      desc "Issue get request to the specified uri"
      validate do |value| Puppet::Type::Web_request.validate_uri(value) end
    end

    newproperty(:post) do
      desc "Issue post request to the specified uri"
      validate do |value| Puppet::Type::Web_request.validate_uri(value) end
    end

    newproperty(:delete) do
      desc "Issue delete request to the specified uri"
      validate do |value| Puppet::Type::Web_request.validate_uri(value) end
    end

    newproperty(:put) do
      desc "Issue put request to the specified uri"
      validate do |value| Puppet::Type::Web_request.validate_uri(value) end
    end

    newparam(:parameters) do
      desc "Hash of parameters to include in the web request"
    end

    newparam(:file_parameters) do
      desc "Hash of file parameters to include in the web request"
    end

    newparam(:follow) do
      desc "Boolean indicating if redirects should be followed"
      newvalues(:true, :false)
    end

    newparam(:store_cookies_at) do
      desc "String indicating where session cookies should be stored"
    end

    newparam(:use_cookies_at) do
      desc "String indicating where session cookies should be read from"
    end

    newparam(:remove_cookies) do
      desc "Boolean indicating if cookies should be removed after using them"
      newvalues(:true, :false)
    end

    newparam(:returns) do
      desc "Expected http return codes of the request"
      defaultto ["200"]
      validate do |value| Puppet::Type::Web_request.validate_http_status(value) end
      munge    do |value| Puppet::Type::Web_request.munge_array_params(value)   end
    end

    newparam(:does_not_return) do
      desc "Unexecpected http return codes of the request"
      validate do |value| Puppet::Type::Web_request.validate_http_status(value) end
      munge    do |value| Puppet::Type::Web_request.munge_array_params(value)   end
    end

    newparam(:contains) do
      desc "XPath to verify as part of the result"
      munge    do |value| Puppet::Type::Web_request.munge_array_params(value)   end
    end

    newparam(:does_not_contain) do
      desc "XPath to verify as not being part of the result"
      munge    do |value| Puppet::Type::Web_request.munge_array_params(value)   end
    end

    newparam(:log_to) do
      desc "Log requests/responses to the specified file or directory"
    end

    newparam(:only_log_errors) do
      desc "Boolean indicating if we should only log responses which did not pass validations"
      newvalues(:true, :false)
    end

    newparam(:if) do
      desc "Invoke request only if the specified request returns true"
    end

    newparam(:unless) do
      desc "Invoke request unless the specified request returns true"
    end

    newparam(:username) do
      desc "HTTP authentication username"
    end
 
    newparam(:password) do
      desc "HTTP authentication password"
    end

end
