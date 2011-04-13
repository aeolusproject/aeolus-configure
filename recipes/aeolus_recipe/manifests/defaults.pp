#Set up some defaults

#Use rpm because it will fail because we don't provide source.
#This is an easy mechanism to have puppet fail when packages
#aren't installed, but also an easy way to tune it back to
#the behavior of installing packages that are missing by
#switching back to yum

Package {provider => 'rpm'}

