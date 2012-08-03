require 'dotify'

module Dotify
  module CLI
    class Listing

      include CLI::Utilities

      attr_reader :collection, :options

      def initialize(collection, options = {})
        @collection = collection
        @options = options
      end

      def count
        collection.count
      end

      def write
        color = Thor::Shell::Color.new
        if self.count > 0
          inform "Dotify is managing #{self.count} files:"
          collection.each { |dot| color.say("  * #{dot.filename}", :yellow) }
        else
          inform "Dotify is not managing any files yet."
        end
      end

    end
  end
end
