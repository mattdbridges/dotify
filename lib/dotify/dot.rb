require 'fileutils'
require 'dotify/errors'

module Dotify

  class NoSymlink; end

  module Actions

    # Link the file from the home directory into Dotify
    def link
      return false if !in_home_dir? || linked?
      if in_home_dir? && !in_dotify?
        FileUtils.cp_r(self.dotfile, self.dotify, :verbose => false)
      end
      FileUtils.rm_rf(self.dotfile, :verbose => false)
      FileUtils.ln_sf(self.dotify, self.dotfile, :verbose => false)
      return true
    end

    def backup_and_link
      if File.exists? self.dotfile
        FileUtils.rm_rf("#{self.dotfile}.bak", :verbose => false)
        FileUtils.mv(self.dotfile, "#{self.dotfile}.bak", :verbose => false)
      end
      FileUtils.ln_sf(self.dotify, self.dotfile, :verbose => false)
    end

    # Unlink the file from Dotify and replace it into the home directory.
    def unlink
      return false unless linked?
      FileUtils.rm_rf(self.dotfile, :verbose => false)
      FileUtils.cp_r(self.dotify, self.dotfile, :verbose => false)
      FileUtils.rm_rf(self.dotify, :verbose => false)
      return true
    end

  end

  class Dot

    include Actions

    attr_accessor :filename, :dotify, :dotfile, :linked

    def initialize(file)
      @filename = File.basename(file)
      self
    end

    def dotify
      @dotify ||= Config.path(@filename)
    end

    def dotfile
      @dotfile ||= Config.home(@filename)
    end

    def linked?
      in_dotify? && linked_to_dotify?
    end

    def in_dotify?
      File.exists?(dotify)
    end

    def in_home_dir?
      File.exists?(dotfile)
    end

    def to_s
      filename
    end

    def inspect
      "#<Dotify::Dot filename: '#{filename}' linked: #{linked?}>"
    end

    def linked_to_dotify?
      symlink == dotify
    end

    def symlink
      if !File.symlink?(dotfile)
        return false
      end
      File.readlink dotfile
    end

  end
end
