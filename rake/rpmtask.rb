# Define a package task library to aid in the definition of RPM
# packages.

require 'rubygems'
require 'rake'
require 'rake/packagetask'

require 'rbconfig' # used to get system arch

module Rake

  # Create a package based upon a RPM spec.
  # RPM packages, can be produced by this task.
  class RpmTask < PackageTask
    # RPM spec containing the metadata for this package
    attr_accessor :rpm_spec

    # RPM build dir
    attr_accessor :topdir

    def initialize(rpm_spec)
      init(rpm_spec)
      yield self if block_given?
      define if block_given?
    end

    def init(rpm_spec)
      @rpm_spec = rpm_spec

      # Parse rpm name / version out of spec
      # FIXME hacky way to do this for now
      #   (would be nice to implement a full blown rpm spec parser for ruby)
      File.open(rpm_spec, "r") { |f|
        contents = f.read
        @name    = contents.scan(/\nName: .*\n/).first.split.last
        @version = contents.scan(/\nVersion: .*\n/).first.split.last
        @release = contents.scan(/\nRelease: .*\n/).first.split.last
        @arch    =  contents.scan(/\nBuildArch: .*\n/)
        if @arch.nil?
          @arch = Config::CONFIG["target_cpu"] # hoping this will work for all cases,
                                               # can just run the 'arch' cmd if we want
        else
          @arch = @arch.first.split.last
        end
        @distro = 'fc13' # FIXME shouldn't be hardcoded
      }
      super(@name, @version)

      @rpmbuild_cmd = 'rpmbuild'
    end

    def define
      super

      directory "#{@topdir}/SOURCES"
      directory "#{@topdir}/SPECS"

      # FIXME support all a spec's subpackages as well
      rpm_file = "#{@topdir}/RPMS/#{@arch}/#{@name}-#{@version}-#{@release}.#{@distro}.#{@arch}.rpm"
      desc "Build the rpms"
      task :rpms => [rpm_file]

      # FIXME properly determine :package build artifact(s) to copy to sources dir, allow users to specify others
      file rpm_file => [:package, "#{@topdir}/SOURCES", "#{@topdir}/SPECS"] do
        cp "#{package_dir}/#{@name}-#{@version}.tgz", "#{@topdir}/SOURCES/"
        cp @rpm_spec, "#{@topdir}/SPECS"
        sh "#{@rpmbuild_cmd} --define '_topdir #{@topdir}' -ba #{@rpm_spec}"
      end
    end
  end
end
