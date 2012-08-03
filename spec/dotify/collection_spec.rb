require 'spec_helper'

module Dotify

  describe Collection do

    let(:collection) { Collection.new(home_files) }
    subject { collection }
    let(:home_files) {
      [
        @bashrc = UnlinkedDot.new(".bashrc"),
        @gitconfig = UnlinkedDot.new(".gitconfig"),
        @vimrc = LinkedDot.new(".vimrc")
      ]
    }
    describe "methods" do
      %w[each linked unlinked].each do |name|
        it { should respond_to name }
      end
    end

    describe "#home and #dotify methods" do
      it "#home should return the right home Dot objects" do
        Config.stub(:ignore).with(:dotfiles).and_return %w[.vimrc]
        Collection.should_receive(:dotfiles).with("/tmp/home/.*").and_return(
          [LinkedDot.new(".."), UnlinkedDot.new("."), LinkedDot.new(".bash_profile"), UnlinkedDot.new(".vimrc"), LinkedDot.new(".zshrc")]
        )
        Collection.home.filenames.should == %w[.bash_profile .zshrc]
      end
      it "#dotify should return the right home Dot objects" do
        Config.stub(:ignore).with(:dotify).and_return %w[.vimrc]
        Collection.should_receive(:dotfiles).with("/tmp/home/.dotify/.*").and_return(
          [LinkedDot.new(".."), UnlinkedDot.new("."), LinkedDot.new(".bash_profile"), UnlinkedDot.new(".vimrc"), LinkedDot.new(".zshrc")]
        )
        Collection.dotify.filenames.should == %w[.bash_profile .zshrc]
      end
    end

    describe Collection, "#filter_only_dots" do
      it 'should not return and . or .. directories' do
        dots = [LinkedDot.new('.'), LinkedDot.new('..'), LinkedDot.new('.vimrc')]
        Collection.stub(:dots).and_return dots
        collection = Collection.new(Collection.dots)
        collection.filter_only_dots.dots.should == Array(dots.last)
      end
    end

    describe Collection, "#ignore" do
      let(:dots) { [LinkedDot.new('.bash_profile'), LinkedDot.new('.zshrc'), LinkedDot.new('.vimrc')] }
      it "should only return files that are not ignored" do
        Collection.stub(:dots).and_return dots
        Config.stub(:ignore).with(:dotfiles).and_return [".zshrc", ".bash_profile"]
        Collection.new(Collection.dots).ignore(:dotfiles).dots.should == Array(dots.last)
      end
    end

    describe Collection, ".dotfiles" do
      let!(:dirfiles) { %w[.vimrc .zshrc .vim] }
      it "should pass the glob to Dir[]" do
        Dir.should_receive(:[]).with(".*").and_return dirfiles
        Collection.dotfiles(".*")
      end
      it "should return an array of Dotify::Dot objects" do
        Dir.stub(:[]).with(".*").and_return dirfiles
        dotfiles = Collection.dotfiles(".*")
        dotfiles.each { |d| d.should be_instance_of Dot }
        dotfiles.first.filename.should == ".vimrc"
        dotfiles[1].filename.should == ".zshrc"
        dotfiles.last.filename.should == ".vim"
      end
    end

    describe Collection, "#filenames" do
      it "should only return the filename strings" do
        Collection.new([LinkedDot.new('.vimrc'), UnlinkedDot.new(".zshrc")]).filenames.should == %w[.vimrc .zshrc]
      end
    end

    describe Collection, "#linked" do
      before do
        collection.stub(:dots).and_return home_files
      end
      let(:linked) { collection.linked }
      subject { linked }
      it { should include @vimrc }
      it { should_not include @gitconfig }
      it { should_not include @bashrc }
      it "should yield the correct Dots" do
        expect { |b| subject.each(&b) }.to yield_successive_args(*linked)
      end
    end

    describe Collection, "#unlinked" do
      before do
        collection.stub(:dots).and_return home_files
      end
      let(:unlinked) { collection.unlinked }
      subject { unlinked }
      it { should include @gitconfig }
      it { should include @bashrc }
      it { should_not include @vimrc }
      it "should yield the correct Dots" do
        expect { |b| subject.each(&b) }.to yield_successive_args(*unlinked)
      end
    end

    it "should call #to_s on the dots" do
      collection.dots.should_receive(:to_s)
      collection.to_s
    end

    it "should call #inspect on the dots" do
      collection.dots.each { |u| u.should_receive(:inspect) }
      collection.inspect
    end

  end
end
