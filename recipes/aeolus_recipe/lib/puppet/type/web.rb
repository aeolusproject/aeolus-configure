Puppet::Type.newtype(:web) do
    @doc = "Issue a request via the world wide web"

    newparam :name

    newproperty(:get) do
      desc "Issue get request to the specified uri"
      # TODO valid value to be a uri
    end

    newproperty(:post) do
      desc "Issue get request to the specified uri"
      # TODO valid value to be a uri
    end

    #newproperty(:delete)
    #newproperty(:put)

    newparam(:parameters) do
      desc "Hash of parameters to include in the web request"
    end

    newparam(:returns) do
      desc "Expected http return codes of the request"
      defaultto "200"
      # TODO validate value(s) is among possible valid http return codes
    end

    newparam(:follow) do
      desc "Boolean indicating if redirects should be followed"
      newvalues(:true, :false)
    end

    newparam(:verify) do
      desc "String to verify as being part of the result"
    end

    newparam(:login) do
      desc "Login parameters to be used if a login is required before making the request"
    end

    newparam(:logout) do
      desc "Logout parameters to be used if a logout is requred after making the request"
    end

    newparam(:unless) do
      desc "Do not run request if the request specified here succeeds"
    end
end
