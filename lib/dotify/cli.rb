require 'thor'
require 'fileutils'
require 'json'
require 'net/http'

require 'dotify'
require 'dotify/config'
require 'dotify/files'
require 'dotify/file_list'
require 'dotify/version_checker'

Dotify::Config.load_config!

module Dotify
  class CLI < Thor
    include Thor::Actions
    default_task :help

    map %w[-v --version] => :version
    map "-s" => :setup
    map "-a" => :add
    map "-r" => :remove
    map "-l" => :link
    map "-u" => :unlink

    def self.source_root
      File.expand_path("../../../templates", __FILE__)
    end

    desc :save, "Commit Dotify files and push to Github"
    method_option :message, :aliases => '-m', :type => :string, :required => false, :desc => "Git commit message to send to Github"
    def save
      Dir.chdir(Config.path) do
        system 'git fetch'
        uncommitted = `git status | wc -l`.chomp.to_i != 2
        if uncommitted
          puts `git status` # show the status output
          message = !options[:message].nil? ? options[:message] : ask("Commit message:", :blue)
          system 'git add .'
          system "git commit -m '#{message.gsub(/[']/, '\\\\\'')}'"
          if `git log origin/master.. --oneline | wc -l`.chomp.to_i != 0
            say 'Pushing up to Github...', :blue
            system 'git push origin master'
          end
        else
          say 'Dotify has nothing to save.', :blue
        end
      end
    end

    desc 'edit [FILE]', "Edit a dotify file"
    method_option :save, :aliases => '-s', :default => false, :type => :boolean, :require => true, :desc => "Save Dotify files and push to Github"
    def edit(filename)
      if Files.linked.include? Files.dotify(filename)
        exec "#{Config.editor} #{Files.dotify(filename)}"
        save if options[:save] == true
      else
        say "'#{Files.filename(filename)}' has not been linked by Dotify. Please run `dotify link #{Files.filename(filename)}` to edit this file.", :blue
      end
    end

    desc :version, "Check your Dotify version"
    def version
      if VersionChecker.out_of_date?
        say "Your version of Dotify is out of date.", :yellow
        say "  Your Version:   #{Dotify::VERSION}", :blue
        say "  Latest Version: #{VersionChecker.version}", :blue
        say "I recommend that you uninstall Dotify completely before updating", :yellow
      else
        say "Your version of Dotify is up to date: #{Dotify::VERSION}", :blue
      end
    rescue Exception
      say "There was an error checking your Dotify version. Please try again.", :red
    end

    desc :setup, "Setup your system for Dotify to manage your dotfiles"
    method_option :install, :type => :boolean, :default => true, :desc => "Install Dotify after setup"
    method_option "edit-config", :type => :boolean, :default => true, :desc => "Edit Dotify's configuration."
    method_options :verbose => true
    def setup
      # Warn if Dotify is already setup
      if !Dotify.installed?
        say "Dotify is already setup", :blue
      end

      # Create the Dotify directory unless it already exists
      unless File.exists?(Config.path)
        empty_directory(Config.path, :verbose => options[:verbose])
      end

      # Create the Dotify config file unless it already exists
      unless File.exists?(Config.file)
        template '.dotrc', Config.file, :verbose => options[:verbose]
      end

      say "Editing config file...", :blue
      sleep 1 # Give a little time for reading the message
      invoke :edit, [Config.file]
      say "Config file updated.", :blue

      # Run install task if specified
      invoke :install if options[:install] == true
    end

    desc :install, "Install files from your home directory into Dotify"
    def install
      invoke :setup unless Dotify.installed?
      invoke :add
    end

    desc "add {{FILENAME}}", "Add a one or more dotfiles to Dotify. (FILENAME is optional)"
    method_option :force, :type => :boolean, :default => false, :aliases => '-f', :desc => "Remove Dotify file(s) without confirmation"
    def add(file=nil)
      not_setup_warning unless Dotify.installed?
      if file.nil?
        Files.uninstalled { |path, file| add_dotify_file(file, options) }
      else
        add_dotify_file(file, options.merge(:single => true))
      end
    end

    desc "remove {{FILENAME}}", "Remove a single dotfile from Dotify (FILENAME is optional)"
    long_desc <<-DESC
      This removes the dotfiles from the Dotify directory and move \
      it back into the home directory. If you decide you want Dotify \
      to manage that file again, you can simply run `dotify add [FILENAME]` \
      to add it back again.
    DESC
    method_option :force, :type => :boolean, :default => false, :aliases => '-f', :desc => "Remove Dotify file(s) without confirmation"
    def remove(file=nil)
      not_setup_warning unless Dotify.installed?
      if file.nil?
        Files.linked { |path, file| remove_dotify_file(file, options) }
      else
        remove_dotify_file(file, options)
      end
    end

    desc 'link {{FILENAME}}', "Link up one or all of your dotfiles (FILENAME is optional)"
    method_option :force, :default => false, :type => :boolean, :aliases => '-f', :desc => "Link dotfiles without confirmation"
    def link(file=nil)
      not_setup_warning unless Dotify.installed?
      if file.nil?
        Files.unlinked do |path, file|
          link_file(file, options)
        end
      else
        link_file(file, options)
      end
    end

    desc 'unlink {{FILENAME}}', "Unlink one or all of your dotfiles (FILENAME is optional)"
    long_desc <<-DESC
      This removes the dotfiles from the home directory and preserves the \
      files in the Dotify directory. This allows you to simply run `dotify link` again \
      should you decide you want to relink anything to the Dotify files.
    DESC
    method_option :force, :default => false, :type => :boolean, :aliases => '-f', :desc => 'Remove all installed dotfiles without confirmation'
    def unlink(file = nil)
      not_setup_warning unless Dotify.installed?
      if file.nil?
        Files.linked do |path, file|
          unlink_file(file, options)
        end
      else
        unlink_file(file, options)
      end
    end

    no_tasks do

      def not_setup_warning
        say('Dotify has not been setup yet! You need to run \'dotify setup\' first.', :yellow)
      end

      def unlink_file(file, options = {})
        file = Files.filename(file)
        dot = Files.dotfile(file)
        dotify = Files.dotify(file)
        if File.exists?(dot) && File.exists?(dotify)
          if options[:force] == true || yes?("Do you want to unlink #{file} from the home directory? [Yn]", :blue)
            FileUtils.rm_rf dot
            say_status :unlinked, dot
          end
        else
          say "'#{file}' does not exist in Dotify.", :blue
        end
      end

      def link_file(file, options = {})
        file = Files.filename(file)
        home = Files.dotfile(file)
        path = Files.dotify(file)
        status = case
                 when !File.exists?(home) then :linked
                 when File.exists?(home) then :replaced; end
        if File.exists?(path)
          if options[:force] == true || yes?("Do you want to link #{file} to the home directory? [Yn]", :blue)
            FileUtils.rm_rf(home, :verbose => false)
            FileUtils.ln_s(path, home, :verbose => false)
            say_status status, home
          end
        else
          say "'#{file}' does not exist in the home directory.", :blue
        end
      end

      def remove_dotify_file(file, options = {})
        file = Files.filename(file)
        home = Files.dotfile(file)
        path = Files.dotify(file)
        if File.exist?(home) && File.exist?(path)
          if options[:force] == true || yes?("Do you want to remove #{file} from Dotify? [Yn]", :blue)
            FileUtils.rm_rf(home, :verbose => false)
            if File.directory? path
              FileUtils.cp_r(path, home, :verbose => false)
            else
              FileUtils.cp(path, home, :verbose => false)
            end
            FileUtils.rm_rf(path, :verbose => false)
            say_status :removed, path
          end
        elsif File.exist?(home) && !File.exist?(path)
          say "The file '#{file}' is not managed by Dotify. Cannot remove.", :blue
        else
          say "The file '~/#{file}' does not exist", :blue
        end
      end

      def add_dotify_file(file, options = {})
        file = Files.filename(file)
        home = Files.dotfile(file)
        path = Files.dotify(file)
        if File.exist?(home)
          if options[:force] == true || yes?("Do you want to add #{file} to Dotify? [Yn]", :blue)
            if File.directory? home
              FileUtils.cp_r(home, path, :verbose => false)
            else
              FileUtils.cp(home, path, :verbose => false)
              say_status :adding, path
            end
          end
        else
          if options[:single] == true
            say "The file '#{file}' doesn't exist or Dotify already manages it.", :blue
          end
        end
      end

    end

  end
end
