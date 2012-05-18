require 'securerandom'

Puppet::Parser::Functions::newfunction(:secure_random,
                                       :type => :rvalue,
                                       :doc => <<ENDDOC
Return SecureRandom.hex using the first parameter as the
number of bytes desired, or 24 bytes by default.
ENDDOC
) do |args|
  if !args[0].nil? && (args[0].responds_to to_i)
    SecureRandom.hex(args[0])
  else
    SecureRandom.hex(24)
  end
end
