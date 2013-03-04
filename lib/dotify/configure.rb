require 'thor/util'

module Dotify
  class Configure

    CONFIG_FILE = "config.rb"

    attr_accessor :options

    def initialize(options = {})
      @options = options
    end

    def options
      @options ||= {}
    end

    def load!
      DSL.new(@options).__evaluate Path.dotify_path(CONFIG_FILE)
    end

    def ignoring(what)
      @ignoring[:shared] | @ignoring[what]
    end

    def setup_default_configuration
      options[:editor] = 'vim'
      options[:shared_ignore] = %w[.DS_Store .Trash .git .svn]
    end

    def method_missing(name, *args, &blk)
      if @options[name.to_sym]
        @options[name.to_sym]
      else
        NullObject.new
      end
    end

    class DSL
      Protected = %r/^__|^object_id|instance_eval$/

      instance_methods.each do |m|
        undef_method m unless m[Protected]
      end

      def initialize(options = {})
        @options = options
      end

      def __evaluate(path)
        if File.exists? path
          instance_eval File.read(path), path, 1
        end
      end

      def platform(which, &blk)
        if which == OperatingSystem.guess
          instance_eval &blk
        end
      end

      # Which editor to use when editing dotfiles and
      # folders.
      def editor(e)
        @options[:editor] = e
      end

      # Default repo to pull/push from
      def repo(name)
        @options[:repo] = name
      end

      def github(gh)
        @options[:github] = gh
      end

      def ignore(where, what)
        @options[:ignore] ||= {}
        @options[:ignore][where] = (@options[:ignore][where] || []) | what
      end

      def manage(filepath, dotify_name = nil)
        name = !dotify_name.nil? ? dotify_name : File.basename(filepath)
        FileList.add ::Dotify::Pointer.new(File.expand_path(filepath), Path.dotify_path(name))
      end

    end

    private

      def default_ignore
        @ignoring ||= {}
        if @ignoring.empty?
          @ignoring[:shared] = %w[. .. .DS_Store]
          @ignoring[:root] = %w[.rbenv .rvm]
          @ignoring[:path] = %w[.git .gitignore .gitmodules]
        end
      end

  end
end
