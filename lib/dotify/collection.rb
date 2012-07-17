module Dotify
  class Collection

    include Enumerable

    attr_accessor :dots

    # Pulls an array of Dots from the home
    # directory.
    def initialize(location = :dotfiles)
      @dots ||= case location
                when :dotfiles then Filter.home
                when :dotify then Filter.dotify
                else
                  raise ArgumentError, "You must specify :dotfiles or :dotify when initializing Collection"
                end
    end

    # Defined each method for Enumerable
    def each(&block)
      dots.each(&block)
    end

    # Linked files are those files which have a
    # symbolic link pointing to the Dotify file.
    def linked
      select(&:linked?)
    end

    # Unlinked files are, of course, the opposite
    # of linked files. These are Dotify files which
    # Have no home dir files that are linked to them.
    def unlinked
      reject(&:linked?)
    end

    def to_s
      dots.to_s
    end

    def inspect
      dots.map(&:inspect)
    end

  end
end
