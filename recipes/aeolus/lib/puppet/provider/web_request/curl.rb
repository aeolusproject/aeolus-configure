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

require 'fileutils'

# Provides an interface to curl using the curb gem for puppet
require 'curb'

# uses nokogiri to verify responses w/ xpath
require 'nokogiri'

class Curl::Easy

  # Format request parameters for the specified request method
  def self.format_params(method, params, file_params)
    if([:get, :delete].include?(method))
      return params.collect { |k,v| "#{k}=#{v}" }.join("&") unless params.nil?
      return ""
    end
    # post, put:
    cparams = []
    params.each_pair      { |k,v| cparams << Curl::PostField.content(k,v) } unless params.nil?
    file_params.each_pair { |k,v| cparams << Curl::PostField.file(k,v)    } unless file_params.nil?
    return cparams
  end

  # Format a url for the specified request method, base uri, and parameters
  def self.format_url(method, uri, params)
    if([:get, :delete].include?(method))
      url = uri
      url +=  ";" + format_params(method, params)
      return url
    end
    # post, put:
    return uri
  end

  # Invoke a new curl request and return result
  def self.web_request(method, uri, params = {})
    raise Puppet::Error, "Must specify http method (#{method}) and uri (#{uri})" if method.nil? || uri.nil?

    curl = self.new

    if params.has_key?(:cookie) && !params[:cookie].nil?
      curl.enable_cookies = true
      curl.cookiefile = params[:cookie]
      curl.cookiejar  = params[:cookie]
    end

    if params.has_key?(:username) && !params[:username].nil?
      curl.username = params[:username]
    end
 
    if params.has_key?(:password) && !params[:password].nil?
      curl.password = params[:password]
    end

    curl.follow_location = (params.has_key?(:follow) && params[:follow])
    request_params = params[:parameters]
    file_params    = params[:file_parameters]

    case(method)
    when 'get'
      curl.url = format_url(method, uri, request_params)
      curl.http_get
      return curl

    when 'post'
      curl.url = format_url(method, uri, request_params)
      curl.multipart_form_post = true if !file_params.nil? && file_params.size > 0
      curl.http_post(*format_params(method, request_params, file_params))
      return curl

    when 'put'
      curl.url = format_url(method, uri, request_params)
      curl.multipart_form_post = true if !file_params.nil? && file_params.size > 0
      curl.http_put(*format_params(method, request_params, file_params))
      return curl

    when 'delete'
      curl.url = format_url(method, uri, request_params)
      curl.http_delete
      return curl
    end
  end

  def valid_status_code?(valid_values=[])
    valid_values.include?(response_code.to_s)
  end

  def valid_xpath?(xpath="/")
    !Nokogiri::HTML(body_str.to_s).xpath(xpath.to_s).empty?
  end

end

# Puppet provider definition
Puppet::Type.type(:web_request).provide :curl do
  desc "Use curl to access web resources"

  def get
    @uri
  end

  def post
    @uri
  end

  def delete
    @uri
  end

  def put
    @uri
  end

  def get=(uri)
    @uri = uri
    process_params('get', @resource, uri)
  end

  def post=(uri)
    @uri = uri
    process_params('post', @resource, uri)
  end

  def delete=(uri)
    @uri = uri
    process_params('delete', @resource, uri)
  end

  def put=(uri)
    @uri = uri
    process_params('put', @resource, uri)
  end

  private

  # Helper to process/parse web parameters
  def process_params(request_method, params, uri)
    begin
      error = nil
      cookies = nil
      if params[:store_cookies_at]
        if File.exist?(params[:store_cookies_at])
          File.truncate(params[:store_cookies_at], 0)
        else
          FileUtils.touch(params[:store_cookies_at])
        end
        cookies = params[:store_cookies_at]
      elsif params[:use_cookies_at]
        cookies = params[:use_cookies_at]
      end

      # verify that we should actually run the request
      return if skip_request?(params, cookies)

      # Actually run the request and verify the result
      result = Curl::Easy::web_request(request_method, uri,
                                       :parameters => params[:parameters],
                                       :file_parameters => params[:file_parameters],
                                       :cookie => cookies,
                                       :follow => params[:follow],
                                       :username => params[:username],
                                       :password => params[:password])

      result_body = result.body_str.to_s

      verify_result(result,
                    :returns          => params[:returns],
                    :does_not_return  => params[:does_not_return],
                    :contains         => params[:contains],
                    :does_not_contain => params[:does_not_contain] )

      result.close

    rescue Exception => e
      error = e
      raise Puppet::Error, "An exception was raised when invoking web request: #{e}"

    ensure
      unless result.nil?
        log_response(:result => result_body,
                     :method => request_method, :uri => uri,
                     :puppet_params => params,  :error => error)
      end
      FileUtils.rm_f(cookies) if params[:remove_cookies]
    end
  end

  # Helper to determine if we should skip the request
  def skip_request?(params, cookie = nil)
    [:if, :unless].each { |c|
      condition = params[c]
      unless condition.nil?
        method = (condition.keys & ['get', 'post', 'delete', 'put']).first
        result = Curl::Easy::web_request(method, condition[method],
                                         :parameters => condition['parameters'],
                                         :file_parameters => condition['file_parameters'],
                                         :cookie => cookie, :follow => params[:follow])
        result_succeeded = true
        begin
          verify_result(result, condition)
        rescue Puppet::Error
          result_succeeded = false
        end
        return true if (c == :if && !result_succeeded) || (c == :unless && result_succeeded)
      end
    }
    return false
  end

  # Helper to verify the response
  def verify_result(result, verify = {})
    verify[:returns]          = verify['returns']          if verify[:returns].nil?          && !verify['returns'].nil?
    verify[:does_not_return]  = verify['does_not_return']  if verify[:does_not_return].nil?  && !verify['does_not_return'].nil?
    verify[:contains]         = verify['contains']         if verify[:contains].nil?         && !verify['contains'].nil?
    verify[:does_not_contain] = verify['does_not_contain'] if verify[:does_not_contain].nil? && !verify['does_not_contain'].nil?

    if !verify[:returns].nil? &&
       !result.valid_status_code?(verify[:returns])
         raise Puppet::Error, "Invalid HTTP Return Code: #{result.response_code},
                               was expecting one of #{verify[:returns].join(", ")}"
    end

    if !verify[:does_not_return].nil? &&
       result.valid_status_code?(verify[:does_not_return])
         raise Puppet::Error, "Invalid HTTP Return Code: #{result.response_code},
                               was not expecting one of #{verify[:does_not_return].join(", ")}"
    end

    if !verify[:contains].nil? &&
       !result.valid_xpath?(verify[:contains])
         raise Puppet::Error, "Expecting #{verify[:contains]} in the result"
    end

    if !verify[:does_not_contain].nil? &&
       result.valid_xpath?(verify[:does_not_contain])
         raise Puppet::Error, "Not expecting #{verify[:does_not_contain]} in the result"
    end
  end

  def log_response(params)
    method  = params[:method]
    uri     = params[:uri]
    result  = params[:result]
    error   = params[:error]
    puppet_params = params[:puppet_params]

    if puppet_params[:log_to]
      return if puppet_params[:only_log_errors] == :true && error.nil?
      logfile = puppet_params[:log_to].strip
      exists = File.exists?(logfile)
      isfile = File.file?(logfile) || (!exists && (logfile[-1].chr != '/'))
      if !isfile
        FileUtils.mkdir_p(logfile) if !exists
	logfile += puppet_params[:name]
      end

      f = File.open(logfile, 'a')
      f.write("=====BEGIN=====\n")
      f.write(Time.now.strftime("%Y-%m-%d %H:%M:%S"))
      f.write(" #{method} request to #{uri}\n")
      f.write(result.to_s)
      f.write("\n=====END=====\n\n")
      f.close
    end
  end
end
