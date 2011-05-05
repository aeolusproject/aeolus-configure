require 'curb'
require 'uuid'
require 'fileutils'

# Helper to invoke the web request w/ curl
def web_request(method, uri, request_params, params = {})
  raise Puppet::Error, "Must specify http method and uri" if method.nil? || uri.nil?

  curl = Curl::Easy.new

  if params.has_key?(:cookie)
    curl.enable_cookies = true
    curl.cookiefile = params[:cookie]
    curl.cookiejar  = params[:cookie]
  end

  curl.follow_location = (params.has_key?(:follow) && params[:follow])

  case(method)
  when 'get'
    url = uri
    url += ";" + request_params.collect { |k,v| "#{k}=#{v}" }.join("&") unless request_params.nil?
    curl.url = url
    curl.http_get
    return curl

  when 'post'
    cparams = []
    request_params.each_pair { |k,v| cparams << Curl::PostField.content(k,v) } unless request_params.nil?
    curl.url = uri
    curl.http_post(cparams)
    return curl

  #when 'put'
  #when 'delete'
  end
end

# Helper to verify the response
def verify_result(result, verify = {})
  returns = (verify.has_key?(:returns) && !verify[:returns].nil?) ? verify[:returns] : "200"
  returns = [returns] unless returns.is_a? Array
  unless returns.include?(result.response_code.to_s)
    raise Puppet::Error, "Invalid HTTP Return Code: #{result.response_code}, 
                          was expecting one of #{returns.join(", ")}"
  end

  if verify.has_key?(:body) && !verify[:body].nil? && !(result.body_str =~ Regexp.new(verify[:body]))
    raise Puppet::Error, "Expecting #{verify[:body]} in the result"
  end
end

# Puppet provider definition
Puppet::Type.type(:web).provide :curl do
  desc "Use curl to access web resources"

  def http_method
    @request_method
  end

  def http_method=(request_method)
    begin
      # Set request method and generate a unique session key
      @request_method = request_method
      session = "/tmp/#{UUID.new.generate}"

      # Invoke a login request if necessary
      if @resource[:login]
        login_params = @resource[:login].reject { |k,v| ['http_method', 'uri'].include?(k) }
        web_request(@resource[:login]['http_method'], @resource[:login]['uri'],
                    login_params, :cookie => session, :follow => @resource[:follow]).close
      end

      # Check to see if we should actually run the request
      skip_request = !@resource[:unless].nil?
      if @resource[:unless]
        result = web_request(@resource[:unless]['http_method'], @resource[:unless]['uri'],
                             @resource[:unless]['parameters'],
                             :cookie => session, :follow => @resource[:follow])
        begin
          verify_result(result,
                        :returns => @resource[:unless]['returns'],
                        :body    => @resource[:unless]['verify'])
        rescue Puppet::Error => e
          skip_request = false
        end
        result.close
      end
      return if skip_request

      # Actually run the request and verify the result
      uri = !@resource[:uri].nil? ? @resource[:uri] : @resource[:name]
      result = web_request(request_method, uri, @resource[:parameters],
                           :cookie => session, :follow => @resource[:follow])
      verify_result(result,
                    :returns => @resource[:returns],
                    :body    => @resource[:verify])
      result.close

      # Invoke a logout request if necessary
      if @resource[:logout]
        logout_params = @resource[:login].reject { |k,v| ['http_method', 'uri'].include?(k) }
        web_request(@resource[:logout]['http_method'], @resource[:logout]['uri'],
                    logout_params, :cookie => session, :follow => @resource[:follow]).close
      end

    rescue Exception => e
      raise Puppet::Error, "An exception was raised when invoking web request: #{e}"

    ensure
      FileUtils.rm_f(session) if @resource[:logout]
    end
  end
end
