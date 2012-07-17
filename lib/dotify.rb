require 'dotify/version'
require 'dotify/errors'

require 'fileutils'

module Dotify

  autoload :Config,     'dotify/config'
  autoload :Collection, 'dotify/collection'
  autoload :Filter,     'dotify/filter'
  autoload :Dot,        'dotify/dot'
  autoload :CLI,        'dotify/cli'

  def self.installed?
    Config.installed?
  end

  def self.version
    VERSION
  end

  def self.collection
    @collection ||= Collection.new
  end
end
