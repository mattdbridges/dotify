require 'dotify'

module Dotify
  class Filter
    class << self

      def home
        result = dots(Config.home('.*'))
        filter_ignore_files!(result, :dotfiles)
      end

      def dotify
        result = dots(Config.path('.*'))
        filter_ignore_files!(result, :dotify)
      end

      def dots(glob)
        filter_dot_directories! Dir[glob].map{ |file| Dot.new(file) }
      end

      def filter_dot_directories!(dots)
        [*dots].delete_if { |f| %w[. ..].include? f.filename }
      end

      def filter_ignore_files!(dots, ignore)
        ignoring = Config.ignore(ignore)
        [*dots].delete_if { |f| ignoring.include?(f.filename) }
      end

      def filenames(dots)
        dots.map(&:filename)
      end

    end
  end
end
