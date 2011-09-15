# Define a package task library to aid in the definition of YUM
# repos.

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

module Rake

  # Create a yum repo with specified rpms
  class YumTask < TaskLib
    # Yum repository location which to build
    attr_accessor :yum_repo

    # RPMs to pull into yum repo
    attr_accessor :rpms

    def initialize(yum_repo)
      init(yum_repo)
      yield self if block_given?
      define if block_given?
    end

    def init(yum_repo)
      @yum_repo = yum_repo
      @createrepo_cmd = 'createrepo'
      @rpms = []
    end

    def define
      desc "Build the yum repo"
      task :create_repo => @rpms do
        @rpms.each { |rpm|
          rpmc = rpm.split('.')
          arch = rpmc[rpmc.size-2]
          arch_dir = @yum_repo + "/" + arch
          FileUtils.mkdir_p arch_dir unless File.directory? arch_dir
          cp_r rpm, "#{@yum_repo}/#{arch}"
        }
        sh "#{@createrepo_cmd} -v #{@yum_repo}"
      end
    end
  end
end
