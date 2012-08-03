module Dotify
  class LinkedDot < Dot
    def in_home_dir?; true; end
    def in_dotify?; true; end
    def linked_to_dotify?; true; end
  end

  class UnlinkedDot < Dot
    def in_home_dir?; false; end
    def in_dotify?; false; end
    def linked_to_dotify?; false; end
  end
end
