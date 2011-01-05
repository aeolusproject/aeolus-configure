# Define a package task library to aid in the definition of YUM
# repos.

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
