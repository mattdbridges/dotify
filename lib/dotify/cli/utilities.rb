require 'thor/shell'

module Dotify
  module CLI
    module Utilities
      include Thor::Shell

      def self.included(base) #:nodoc:
        base.extend(self)
      end

      # Only run the passed block if Dotify is installed.
      #
      # Usage:
      #
      #   run_if_installed do
      #     # ...code to run...
      #   end
      #
      # To run without the output warning, pass false as a parameter.
      #
      # Usage:
      #
      #   run_if_installed(false) do
      #     # ...code to run...
      #   end
      #
      def run_if_installed(output = true, &blk)
        return yield if Config.installed?
        inform "You need to run `dotify setup` before you can run this task." if output
      end

      # Only run the passed block if Dotify is not installed.
      #
      # Usage:
      #
      #   run_if_not_installed do
      #     # ...code to run...
      #   end
      #
      # To run without the output warning, pass false as a parameter.
      #
      # Usage:
      #
      #   run_if_not_installed(false) do
      #     # ...code to run...
      #   end
      #
      def run_if_not_installed(output = true, &blk)
        return yield unless Config.installed?
        inform "You need to uninstall Dotify before you can run this task" if output
      end

      def inform(message)
        say message, :blue
      end

      def caution(message)
        say message, :red
      end

      def say(message, color)
        Thor::Shell::Color.new.say(" ** #{message}", color)
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
end
