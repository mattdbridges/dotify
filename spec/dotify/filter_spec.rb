require 'spec_helper'

module Dotify
  describe Filter do

    describe Filter, "#home" do
      it "should call Filter#dots with the correct path" do
        Filter.should_receive(:dots).with("/tmp/home/.*").once.and_return([])
        Filter.home
      end
      it "should drop files that have been specified to be ignored" do
        Filter.stub(:dots) do
          [
            Dot.new('.zshrc'),
            Dot.new('.bashrc'),
            Dot.new('.vimrc'),
            Dot.new('.gitconfig')
          ]
        end
        Config.stub(:ignore).with(:dotfiles).and_return %w[.zshrc .vimrc]
        result = Filter.home.map(&:filename)
        result.should include '.bashrc'
        result.should include '.gitconfig'
        result.should_not include '.zshrc'
        result.should_not include '.vimrc'
      end
    end

    describe Filter, "#dotify" do
      it "should call Filter#dots with the correct path" do
        Filter.should_receive(:dots).with("/tmp/home/.dotify/.*").once.and_return([])
        Filter.dotify
      end
      it "should drop files that have been specified to be ignored" do
        Filter.stub(:dots) do
          [
            Dot.new(".gitconfig"),
            Dot.new('.vimrc'),
            Dot.new('.zshrc'),
            Dot.new('.bashrc'),
            Dot.new('.fakefile')
          ]
        end
        Config.stub(:ignore).with(:dotify).and_return %w[.gitconfig .bashrc]
        result = Filter.filenames(Filter.dotify)
        result.should include '.vimrc'
        result.should include '.zshrc'
        result.should include '.fakefile'
        result.should_not include '.bashrc'
        result.should_not include '.gitconfig'
      end
    end

    describe Filter, "#dots" do
      let(:glob) { '/spec/test/.*' }
      it "should pull the glob of dotfiles from a directory" do
        Dir.should_receive(:[]).with(glob).and_return(%w[. .. /spec/test/.vimrc /spec/test/.bashrc /spec/test/.zshrc])
        Filter.dots(glob)
      end
      describe "return values" do
        before do
          Dir.stub(:[]).with(glob).and_return(%w[. .. /spec/test/.vimrc /spec/test/.bashrc /spec/test/.zshrc])
        end
        let(:files) { Filter.dots(glob) }
        it "should return the right directories" do
          f = files.map(&:filename)
          f.should include '.vimrc'
          f.should include '.bashrc'
          f.should include '.zshrc'
        end
        it "should filter out . and .. directories" do
          f = files.map(&:filename)
          f.should_not include '.'
          f.should_not include '..'
        end
      end
    end

    describe Filter, "#filenames" do
      let(:files) { [
        Dot.new('.vimrc'), Dot.new('.bashrc'), Dot.new('.zshrc')
      ] }
      it "return only the filenames of the dots" do
        result = Filter.filenames(files)
        result.should include '.vimrc'
        result.should include '.bashrc'
        result.should include '.zshrc'
      end
    end


  end
end
