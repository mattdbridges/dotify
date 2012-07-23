require 'rubygems'
require 'thor'
require 'fileutils'
require 'git'
require 'net/http'

require 'dotify'
require 'dotify/version_checker'

module Dotify

  class CLI < Thor
    include Thor::Actions
    default_task :help

    map %w[-v --version] => :version
    map "-s" => :setup
    map "-l" => :link
    map "-u" => :unlink

    def self.source_root
      File.expand_path("../../../templates", __FILE__)
    end

    desc :save, "Save Dotify files and push to Github."
    method_option :message, :aliases => '-m', :type => :string, :required => false, :desc => "Git commit message to send to Github"
    method_option :force,   :aliases => '-f', :type => :boolean, :default => false, :desc => "Do not ask for confirmation when adding files to the staging area."
    method_option :debug,   :aliases => '-d', :type => :boolean, :default => false, :desc => "Show error messages if there is a Git failure."
    method_option :verbose, :aliases => '-v', :type => :boolean, :default => true,  :desc => "Display file creation and status updates."
    method_option :push,    :aliases => '-p', :type => :boolean, :default => false, :desc => "Force the push to the remote repository."
    def save
      if File.exists? Config.path('.git') # if the Dotify directory has been made a git repo
        repo = ::Git.open(Config.path)
        changed = repo.status.changed
        if changed.size > 0
          changed.each_pair do |file, status|
            say_status :changed, status.path, :verbose => options[:verbose]
            if options[:force] || yes?("Do you want to add '#{status.path}' to the Git index? [Yn]", :blue)
              repo.add status.path
              say_status :added, status.path, :verbose => options[:verbose]
            end
          end
          message = !options[:message].nil? ? options[:message] : ask("Commit message:", :blue)
          say message, :yellow, :verbose => options[:verbose]
          repo.commit(message)
        else
          inform "No files have been changed in Dotify."
        end
        if options[:push] || yes?("Would you like to push these changed to Github? [Yn]", :blue)
          inform 'Pushing up to Github...'
          begin
            repo.push
          rescue Exception => e
            say "There was a problem pushing to your remote repo.", :red
            say("Git Error: #{e.message}", :red) if options[:debug]
            return
          end
          inform "Successfully pushed!"
        end
      else
        inform 'Dotify has nothing to save.'
      end
    end

    desc 'github [USERNAME]/[REPO]', "Install the dotfiles from a Github repo into Dotify. (Backs up any files that would be overwritten)"
    method_option :debug, :aliases => '-d', :type => :boolean, :default => false, :desc => "Show error messages if there is a Git failure."
    def github(repo)
      return inform "Dotify has already been setup." if Dotify.installed?
      git_repo_name = "git@github.com:#{repo}.git"
      inform "Pulling #{repo} from Github into #{Config.path}..."
      Git.clone(git_repo_name, Config.path)
      inform "Backing up dotfile and installing Dotify files..."
      Collection.new(:dotify).each { |file| file.backup_and_link }
      if File.exists? File.join(Config.path, ".gitmodules")
        inform "Initializing and updating submodules in Dotify now..."
        system "cd #{Config.path} && git submodule init &> /dev/null && git submodule update &> /dev/null"
      end
      inform "Successfully installed #{repo} from Dotify!"
    rescue Git::GitExecuteError => e
      say "[ERROR]: There was an problem pulling from #{git_repo_name}.\nPlease make sure that the specified repo exists and you have access to it.", :red
      say "Git Error: #{e.message}", :red if options[:debug]
    end

    desc :list, "List the installed dotfiles"
    def list
      inform "Dotify is managing #{Dotify.collection.linked.count} files:\n"
      Dotify.collection.linked.each do |dot|
        say "   * #{dot.filename}", :yellow
      end
      $stdout.write "\n"
    end

    desc 'edit [FILE]', "Edit a dotify file"
    method_option :save, :aliases => '-s', :default => false, :type => :boolean, :require => true, :desc => "Save Dotify files and push to Github"
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
      if VersionChecker.out_of_date?
        say "Your version of Dotify is out of date.", :yellow
        inform "  Your Version:   #{Dotify.version}"
        inform "  Latest Version: #{VersionChecker.version}"
        say "I recommend that you uninstall Dotify completely before updating", :yellow
      else
        inform "Your version of Dotify is up to date: #{Dotify.version}"
      end
    rescue Exception => e
      say "There was an error checking your Dotify version. Please try again.", :red
      say VersionChecker.handle_error(e) if options[:verbose] == true
    end

    desc :setup, "Setup your system for Dotify to manage your dotfiles"
    method_option :install, :type => :boolean, :default => true, :desc => "Install Dotify after setup"
    method_option "edit-config", :type => :boolean, :default => true, :desc => "Edit Dotify's configuration."
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

      inform "Editing config file..."
      sleep 0.5 # Give a little time for reading the message
      invoke :edit, [Config.file]
      inform "Config file updated."

      # Run install task if specified
      invoke :install if options[:install] == true
    end

    desc :install, "Install files from your home directory into Dotify"
    def install
      invoke :setup unless Dotify.installed?
      invoke :link
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
      return not_setup_warning unless Dotify.installed?
      # Link a single file
      return file_action :link, Dot.new(file), options unless file.nil?
      # Relink the files
      return Dotify.collection.linked.each { |file| file_action(:link, file, options) } if options[:relink]
      # Link the files
      Dotify.collection.unlinked.each { |file| file_action(:link, file, options) }
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
      return not_setup_warning unless Dotify.installed?
      # Unlink a single file
      return file_action :unlink, Dot.new(file), options unless file.nil?
      # Unlink the files
      Dotify.collection.linked.each { |file| file_action(:unlink, file, options) }
    end

    private

      def inform(message)
        say message, :blue
      end

      def not_setup_warning
        say "Dotify has not been setup yet! You need to run 'dotify setup' first.", :yellow
      end

      def file_action(action, file, options = {})
        case action.to_sym
        when :link
          return inform "'#{file.dotfile}' does not exist." unless file.in_home_dir?
          return say_status :linked, file.dotfile if file.linked?
        when :unlink
          return inform "'#{file}' does not exist in Dotify."unless file.linked?
        else
          say "You can't run the action :#{action} on a file."
        end

        if options[:force] == true || yes?("Do you want to #{action} #{file} #{action.to_sym == :link ? :to : :from} Dotify? [Yn]", :blue)
          file.send(action) if file.respond_to? action
          say_status "#{action}ed", file.dotfile
        end
      end

  end
end
