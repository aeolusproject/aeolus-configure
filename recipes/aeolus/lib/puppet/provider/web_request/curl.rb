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

# Helper to process/parse web parameters
def process_params(request_method, params, uri)
  begin
    # Set request method and generate a unique session key
    session = "/tmp/#{UUID.new.generate}"

    # Invoke a login request if necessary
    if params[:login]
      login_params = params[:login].reject { |k,v| ['http_method', 'uri'].include?(k) }
      web_request(params[:login]['http_method'], params[:login]['uri'],
                  login_params, :cookie => session, :follow => params[:follow]).close
    end

    # Check to see if we should actually run the request
    skip_request = !params[:unless].nil?
    if params[:unless]
      result = web_request(params[:unless]['http_method'], params[:unless]['uri'],
                           params[:unless]['parameters'],
                           :cookie => session, :follow => params[:follow])
      begin
        verify_result(result,
                      :returns => params[:unless]['returns'],
                      :body    => params[:unless]['verify'])
      rescue Puppet::Error => e
        skip_request = false
      end
      result.close
    end
    return if skip_request

    # Actually run the request and verify the result
    uri = params[:name] if uri.nil?
    result = web_request(request_method, uri, params[:parameters],
                         :cookie => session, :follow => params[:follow])
    verify_result(result,
                  :returns => params[:returns],
                  :body    => params[:verify])
    result.close

    # Invoke a logout request if necessary
    if params[:logout]
      logout_params = params[:login].reject { |k,v| ['http_method', 'uri'].include?(k) }
      web_request(params[:logout]['http_method'], params[:logout]['uri'],
                  logout_params, :cookie => session, :follow => params[:follow]).close
    end

  rescue Exception => e
    raise Puppet::Error, "An exception was raised when invoking web request: #{e}"

  ensure
    FileUtils.rm_f(session) if params[:logout]
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

  def get=(uri)
    @uri = uri
    process_params('get', @resource, uri)
  end

  def post=(uri)
    @uri = uri
    process_params('post', @resource, uri)
  end
end
