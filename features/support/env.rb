require 'rubygems'
require 'thor/util'
require 'fileutils'

$:.unshift(File.dirname(__FILE__) + '/../../lib')
require 'dotify'
require 'cucumber/rspec/doubles'
require 'aruba/cucumber'

Before('@slow_process') do
  @aruba_timeout_seconds = 30
  @aruba_io_wait_seconds = 30
end

Before do
  @__orig_home = ENV["HOME"]
  @tmp_home = "/tmp/dotify-test"

  ## Aruba config ##
  @aruba_timeout_seconds = 6
  @dirs = [@tmp_home]
  ENV["PATH"] = "#{File.expand_path(File.dirname(__FILE__) + '/../../bin')}#{File::PATH_SEPARATOR}#{ENV['PATH']}"

  # Stub CLI say method
  @cli = Dotify::CLI::Base.new
  @cli.stub(:say)

  ENV["HOME"] = @tmp_home
  `rm -rf #{File.join(ENV["HOME"], '.bash_profile')}`
  `rm -rf #{File.join(ENV["HOME"], '.gemrc')}`
end

After do
  FileUtils.rm_rf @tmp_home
  ENV["HOME"] = @__orig_home
end
