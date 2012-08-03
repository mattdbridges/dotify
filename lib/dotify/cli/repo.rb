require 'dotify/cli/utilities'
require 'thor/actions'
require 'git'

module Dotify
  module CLI
    class Repo

      include Utilities

      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      def save
        self.class.run_if_git_repo do
          repo = ::Git.open(Dotify::Config.path)
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
          if options[:push] || yes?("Would you like to push these changed to Repo? [Yn]", :blue)
            inform 'Pushing up to Repo...'
            begin
              repo.push
            rescue Exception => e
              say "There was a problem pushing to your remote repo.", :red
              say("Git Error: #{e.message}", :red) if options[:debug]
              return
            end
            inform "Successfully pushed!"
          end
        end
      end

      def pull(repo)
        run_if_not_installed do
          puller = Pull.new(repo, Config.path, options)
          puller.clone
          Dot.new(".dotrc").backup_and_link # Link the new .dotrc file before trying to link the new files
          Collection.dotify.each { |file| file.backup_and_link }
          puller.initialize_submodules
          puller.finish
        end
      rescue Git::GitExecuteError => e
        caution "[ERROR]: There was an problem pulling from #{git_repo_name}.\nPlease make sure that the specified repo exists and you have access to it."
        caution "Git Error: #{e.message}" if options[:debug]
      end

      # CLI::Repo::Pull
      #
      # Handles the behavior of the CLI when pulling
      # a repo from Repo.
      #
      class Pull

        # Need to be able to read the repo that is being pulled, the
        # path that it is being cloned to, and any options passsed down
        # from the CLI.
        attr_reader :repo, :path, :options

        include Utilities

        # It receives a repo name in the form of [USERNAME]/[REPO] and
        # the path into which is should be initialized as well as a few options
        # to specify behavior.
        #
        # === Parameters
        # repo<String>:: The [USERNAME]/[REPO] of the dotfiles
        # path<String>:: The absolute path to clone the repo into.
        # options<Hash>:: Options to specify behavior
        #
        # === Example
        #
        #   pull = Pull.new("mattdbridges/dots", "/Users/mattbridges//.dotify", { :force => true, :ssh => true })
        #
        def initialize(repo, path, options = {})
          @repo, @path, @options = repo, path, options
          inform "Backing up dotfile and installing Dotify files..."
        end

        # Clone the repo from the url into the specified path.
        def clone
          inform "Pulling #{repo} from Repo into #{path}..."
          Git.clone(url, path)
        end

        def inform(message) #:nodoc:
          super(message) if options[:verbose]
        end

        def finish #:nodoc:
          inform "Dotify successfully installed #{repo} from Repo!"
        end

        # The URL of the Repo repo to pull.
        #
        # If the options passed into Pull.new include `{ :ssh => true }`, then
        # The URL will be in the SSH format. By default, the `:ssh` is `false`,
        # so it will return the Git URL format.
        def url
          "git#{github_url}#{repo}.git"
        end

        # Initialize the submodules of the repo if any are present
        def initialize_submodules
          if File.exists? File.join(path, ".gitmodules")
            inform "Initializing and updating submodules in Dotify now..."
            system "cd #{path} && git submodule init &> /dev/null && git submodule update &> /dev/null"
          end
        end

        # Determine the type of Repo repo url to use when pulling
        def github_url
          use_ssh_repo? ? '@github.com:' : '://github.com/'
        end

        def use_ssh_repo?
          options.fetch(:ssh, false) == true
        end

      end

      def self.run_if_git_repo
        return yield if File.exists? Config.path('.git')
        inform "You need to make ~/.dotify a Git repo to run this task."
      end

    end
  end
end
