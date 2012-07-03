require 'dotify'
require 'thor/util'
require 'yaml'

module Dotify
  class Config

    DIRNAME = '.dotify'
    CONFIG_FILE = '.dotrc'
    EDITOR = 'vim'
    DEFAULT_IGNORE = {
      :dotify => %w[.git .gitmodule],
      :dotfiles => %w[.DS_Store .Trash .dropbox .dotify]
    }

    class << self

      def dirname
        @dirname ||= DIRNAME
      end

      def installed?
        File.directory?(File.join(home, dirname))
      end

      def path
        File.join(home, dirname)
      end

      def editor
        config.fetch(:editor, 'vim')
      end

      def load_config!
        config = File.exists?(file) ? (YAML.load_file(file) || {}) : {}
        symbolize_keys!(config)
      end

      def ignore(what)
        (config.fetch(:ignore, {}).fetch(what, []) + DEFAULT_IGNORE.fetch(what, [])).uniq
      end

      def config
        @config || load_config!
      end

      def home
        Thor::Util.user_home
      end

      def file
        File.join(home, CONFIG_FILE)
      end

      private

        def symbolize_keys!(opts)
          sym_opts = {}
          opts.each do |key, value|
            sym_opts[key.to_sym] = value.is_a?(Hash) ? symbolize_keys!(value) : value
          end
          sym_opts
        end

    end
  end
end
