# Define a package task library to aid in the definition of RPM
# packages.

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

require 'rubygems'
require 'rake'
require 'rake/packagetask'

require 'rbconfig' # used to get system arch

module Rake

  # Create a package based upon a RPM spec.
  # RPM packages, can be produced by this task.
  class RpmTask < PackageTask
    # filename for output RPM spec
    attr_accessor :rpm_spec

    # RPM build dir
    attr_accessor :topdir

    # Include extra_release information in the rpm
    attr_accessor :include_extra_release

    def initialize(rpm_spec, args = {})
      init(rpm_spec,args)
      yield self if block_given?
      define if block_given?
    end

    def init(rpm_spec,args)
      @rpm_spec = rpm_spec
      
      if args[:suffix]
        rpm_spec_in = @rpm_spec + args[:suffix]
        @include_extra_release = eval `grep -q '^[[:space:]]*Release:[[:space:]]*0' #{rpm_spec_in} && echo true || echo false`

        git_head = `git log -1 --pretty=format:%h`
        extra_release = @include_extra_release ? ("." + Time.now.strftime("%Y%m%d%H%M%S").gsub(/\s/, '') + "git" + "#{git_head}") : ''

        if args[:pkg_version]
          pkg_version = args[:pkg_version]
          `sed -e "s|@VERSION@|#{pkg_version}|;s|^\\(Release:[^%]*\\)|\\1#{extra_release}|" #{rpm_spec_in} > #{@rpm_spec}`
        else
          `sed -e "s|^\\(Release:[^%]*\\)|\\1#{extra_release}|" #{rpm_spec_in} > #{@rpm_spec}`
        end
      end

      # parse this out of the rpmbuild macros,
      # not ideal but better than hardcoding this
      File.open('/etc/rpm/macros.dist', "r") { |f|
        f.read.scan(/%dist\s*\.(.*)\n/)
        @distro = $1
      }

      # Parse rpm name / version out of spec
      # FIXME hacky way to do this for now
      #   (would be nice to implement a full blown rpm spec parser for ruby)
      File.open(rpm_spec, "r") { |f|
        contents = f.read
        @name    = contents.scan(/\nName: .*\n/).first.split.last
        @version = contents.scan(/\nVersion: .*\n/).first.split.last
        @release = contents.scan(/\nRelease: .*\n/).first.split.last
        @release.gsub!("%{?dist}", ".#{@distro}")
        @arch    =  contents.scan(/\nBuildArch: .*\n/) # TODO grab local arch if not defined
        if @arch.nil?
          @arch = Config::CONFIG["target_cpu"] # hoping this will work for all cases,
                                               # can just run the 'arch' cmd if we want
        else
          @arch = @arch.first.split.last
        end
      }
      super(@name, @version)

      @rpmbuild_cmd = 'rpmbuild'
    end

    def define
      super

      directory "#{@topdir}/SOURCES"
      directory "#{@topdir}/SPECS"

      desc "Build the rpms"
      task :rpms, [:include_extra_release] => [rpm_file]

      # FIXME properly determine :package build artifact(s) to copy to sources dir
      file rpm_file, [:include_extra_release] => [:package, "#{@topdir}/SOURCES", "#{@topdir}/SPECS"] do |t,args|
        cp "#{package_dir}/#{@name}-#{@version}.tgz", "#{@topdir}/SOURCES/"
        cp @rpm_spec, "#{@topdir}/SPECS"
        sh "#{@rpmbuild_cmd} " +
           "--define '_topdir #{@topdir}' " +
           "-ba #{@rpm_spec}"
      end
    end

    def rpm_file
      # FIXME support all a spec's subpackages as well
      "#{@topdir}/RPMS/#{@arch}/#{@name}-#{@version}-#{@release}.#{@arch}.rpm"
    end
  end
end
