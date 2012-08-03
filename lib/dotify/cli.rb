require 'rubygems'
require 'thor'
require 'fileutils'
require 'net/http'

require 'dotify'
require 'dotify/cli/listing'

module Dotify
  module CLI
    class Base < Thor

      include CLI::Utilities
      include Thor::Actions

      default_task :help

      map %w[-v --version] => :version
      map "-s" => :setup
      map "-l" => :link
      map "-u" => :unlink

      def self.source_root
        File.expand_path("../../../templates", __FILE__)
      end

      desc :save, "Save Dotify files and push to Repo."
      method_option :message, :aliases => '-m', :type => :string, :required => false, :desc => "Git commit message to send to Repo"
      method_option :force,   :aliases => '-f', :type => :boolean, :default => false, :desc => "Do not ask for confirmation when adding files to the staging area."
      method_option :debug,   :aliases => '-d', :type => :boolean, :default => false, :desc => "Show error messages if there is a Git failure."
      method_option :verbose, :aliases => '-v', :type => :boolean, :default => true,  :desc => "Display file creation and status updates."
      method_option :push,    :aliases => '-p', :type => :boolean, :default => false, :desc => "Force the push to the remote repository."
      def save
        Repo.new(options).save
      end

      desc 'github [USERNAME]/[REPO]', "Install the dotfiles from a Repo repo into Dotify. (Backs up any files that would be overwritten)"
      method_option :debug, :aliases => '-d', :type => :boolean, :default => false, :desc => "Show error messages if there is a Git failure."
      def github(repo)
        Repo.new(options).pull(repo)
      end

      desc :list, "List the installed dotfiles"
      def list
        Listing.new(Dotify.collection.linked, options).write
      end

      desc 'edit [FILE]', "Edit a dotify file"
      method_option :save, :aliases => '-s', :default => false, :type => :boolean, :require => true, :desc => "Save Dotify files and push to Repo"
      def edit(file)
        file = Dot.new(file)
        if file.linked?
          exec "#{Config.editor} #{file.dotify}"
          save if options[:save] == true
        else
          inform "'#{file}' has not been linked by Dotify. Please run `dotify link #{file}` to edit this file."
        end
      end

      desc :version, "Check your Dotify version"
      method_option :verbose, :aliases => '-v', :default => false, :type => :boolean, :desc => "Output any errors that occur during the Version check."
      method_option :check, :aliases => '-c', :default => false, :type => :boolean, :desc => "Check Rubygems.org to see if your installed version of Dotify is out of date."
      def version
        return say "Dotify Version: v#{Dotify.version}", :blue unless options[:check]
        if Version.out_of_date?
          say "Your version of Dotify is out of date.", :yellow
          inform "  Your Version:   #{Dotify.version}"
          inform "  Latest Version: #{Version.version}"
          say "I recommend that you uninstall Dotify completely before updating", :yellow
        else
          inform "Your version of Dotify is up to date: #{Dotify.version}"
        end
      rescue Exception => e
        caution "There was an error checking your Dotify version. Please try again."
        say Version.handle_error(e) if options[:verbose] == true
      end

      desc :setup, "Setup your system for Dotify to manage your dotfiles"
      method_option :install, :type => :boolean, :default => false, :desc => "Install Dotify after setup"
      method_option "edit-config", :type => :boolean, :default => false, :desc => "Edit Dotify's configuration."
      method_options :verbose => true
      def setup
        # Warn if Dotify is already setup
        inform "Dotify is already setup" if Dotify.installed?

        # Create the Dotify directory unless it already exists
        unless File.exists?(Config.path)
          empty_directory(Config.path, :verbose => options[:verbose])
        end

        # Create the Dotify config file unless it already exists
        unless File.exists?(Config.file)
          template '.dotrc', Config.file, :verbose => options[:verbose]
        end

        if options["edit-config"] == true
          inform "Editing config file..."
          sleep 0.5 # Give a little time for reading the message
          invoke :edit, [Config.file]
          inform "Config file updated."
        end

        # Run install task if specified
        invoke :install if options[:install] == true
      end

      desc :install, "Install files from your home directory into Dotify"
      def install
        setup unless Dotify.installed?
        link
      end

      desc 'link [[FILENAME]]', "Link up one or all of your dotfiles (FILENAME is optional)"
      long_desc <<-DESC
        This task takes a file from the home directory, \
        moves it into Dotify, and symlinks the file in the \
        home directory to the corresponding file in Dotify.
      DESC
      method_option :force,   :default => false, :type => :boolean, :aliases => '-f', :desc => "Link dotfiles without confirmation"
      method_option :relink,  :default => false, :type => :boolean, :aliases => '-r', :desc => "Relink files already in the"
      def link(file = nil)
        run_if_installed do
          # Link a single file
          return file_action :link, Dot.new(file), options unless file.nil?
          # Relink the files
          return Dotify.collection.linked.each { |file| file_action(:link, file, options) } if options[:relink]
          # Link the files
          Dotify.collection.unlinked.each { |file| file_action(:link, file, options) }
        end
      end

      desc 'unlink [[FILENAME]]', "Unlink one or all of your dotfiles (FILENAME is optional)"
      long_desc <<-DESC
        This task unlinks the dotfile from Dotify and \
        moves it back into the home directory. This will \
        only be run if the file is symlinked to the corresponsing \
        file in Dotify.
      DESC
      method_option :force, :default => false, :type => :boolean, :aliases => '-f', :desc => 'Remove all installed dotfiles without confirmation'
      def unlink(file = nil)
        run_if_installed do
          # Unlink a single file
          return file_action :unlink, Dot.new(file), options unless file.nil?
          # Unlink the files
          Dotify.collection.linked.each { |file| file_action(:unlink, file, options) }
        end
      end

    end
  end
end
