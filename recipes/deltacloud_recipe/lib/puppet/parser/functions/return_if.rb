module Puppet::Parser::Functions
  newfunction(:return_if, :type => :rvalue) do |args|
    condition = args[0]
    value     = args[1]
    condition ? value : []
  end
end
