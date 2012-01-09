Puppet::Parser::Functions::newfunction(:ensure_vardef,
                                       :type => :rvalue,
                                       :doc => <<ENDDOC
Validate that one or more variables are defined.  Returns the first
undefined variable name found; if all variables are defined, return
false.
ENDDOC
) do |args|
  undefined = false
  args.each do |param|
    undefined = param if ['', :undefined].include?(lookupvar(param)) and not undefined
  end
  undefined
end
