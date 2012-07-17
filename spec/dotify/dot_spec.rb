require 'spec_helper'
require 'dotify/dot'

class DummyDot
  def dotfile
    '.dummy'
  end
  def dotify
    '.dotify/.dummy'
  end

  def linked?; end
  def in_home_dir?; true; end
  def in_dotify?; true; end
end

module Dotify

  describe Actions do
    let!(:dummy) { DummyDot.new }
    subject { dummy }
    before { dummy.extend(Actions) }
    it { should respond_to :link }
    it { should respond_to :unlink }

    describe Actions, "#link" do
      before do
        subject.stub(:linked?) { false }
      end
      it "should not do anything if the file is linked" do
        subject.stub(:linked?) { true }
        subject.link.should == false
      end
      it "should not do anything if the is not in the home directory" do
        subject.stub(:linked?) { true }
        subject.stub(:in_home_dir?) { false }
        subject.link.should == false
      end
      it "should copy the file from the home directory if it is not in Dotify" do
        FileUtils.should_receive(:rm_rf).with(subject.dotfile, :verbose => false)
        FileUtils.should_receive(:ln_sf).with(subject.dotify, subject.dotfile, :verbose => false)
        subject.link
      end
      it "should simply remove the file from the home and relink it" do
        subject.stub(:in_dotify?) { false }
        FileUtils.should_receive(:cp_r).with(subject.dotfile, subject.dotify, :verbose => false)
        FileUtils.stub(:rm_rf)
        FileUtils.stub(:ln_sf)
        subject.link
      end
    end
    describe Actions, "#backup_and_link" do
      it "should call the right FileUtils methods" do
        FileUtils.should_receive(:rm_rf).with("#{subject.dotfile}.bak", :verbose => false)
        FileUtils.should_receive(:mv).with(subject.dotfile, "#{subject.dotfile}.bak", :verbose => false)
        FileUtils.should_receive(:ln_sf).with(subject.dotify, subject.dotfile, :verbose => false)
        subject.backup_and_link
      end
    end
    describe Actions, "#unlink" do
      it "should not do anything if the file is not linked" do
        subject.stub(:linked?) { false }
        FileUtils.should_not_receive(:rm_rf)
        FileUtils.should_not_receive(:cp_r)
        FileUtils.should_not_receive(:rm_rf)
        subject.unlink.should == false
      end
      it "should call the right FileUtils methods" do
        subject.stub(:linked?) { true }
        FileUtils.should_receive(:rm_rf).with(subject.dotfile, :verbose => false)
        FileUtils.should_receive(:cp_r).with(subject.dotify, subject.dotfile, :verbose => false)
        FileUtils.should_receive(:rm_rf).with(subject.dotify, :verbose => false)
        subject.unlink
      end
    end
  end
  describe Dot do

    describe "populates the attributes correctly" do
      let(:dot) { Dot.new(".vimrc") }
      subject { dot }
      it { should respond_to :filename }
      it { should respond_to :dotify }
      it { should respond_to :dotfile }
      it { should respond_to :dotfile }
      it { should respond_to :linked? }
      it { should respond_to :linked }

      it "should set the attributes properly" do
        dot.filename.should == '.vimrc'
        dot.dotify.should == '/tmp/home/.dotify/.vimrc'
        dot.dotfile.should == '/tmp/home/.vimrc'
      end
      it "should puts the filename" do
        dot.to_s.should == dot.filename
      end
    end

    describe "existence in directories" do
      let(:dot) { Dot.new(".bashrc") }
      it "should check for the existence in the home directory" do
        File.stub(:exists?).with(dot.dotfile).and_return true
        dot.in_home_dir?.should == true
      end
      it "should return false if the file is not in the home directory" do
        File.stub(:exists?).with(dot.dotfile).and_return false
        dot.in_home_dir?.should_not == true
      end
      it "should check for the existence of the file in Dotify" do
        File.stub(:exists?).with(dot.dotify).and_return true
        dot.in_dotify?.should == true
      end
      it "should return false if the file is not in Dotify" do
        File.stub(:exists?).with(dot.dotify).and_return false
        dot.in_dotify?.should == false
      end
    end

    describe Dot, "#linked_to_dotify?" do
      let(:dot) { Dot.new(".bashrc") }
      it "should return false when an error is raised" do
        dot.stub(:symlink).and_return NoSymlink
        dot.linked_to_dotify?.should be_false
      end
      it "should return true if the dotfile is linked to the Dotify file" do
        dot.stub(:symlink).and_return dot.dotify
        dot.linked_to_dotify?.should be_true
      end
      it "should return false if the dotfile is not linked to the Dotify file" do
        File.stub(:readlink).with(dot.dotfile).and_return '/tmp/home/.another_file'
        dot.linked_to_dotify?.should be_false
      end
    end

    describe Dot, "#linked?" do
      let(:dot) { Dot.new(".bashrc") }
      before do
        dot.stub(:in_dotify?).and_return true # stub identical file check
      end
      it "should return true if all checks work" do
        dot.stub(:linked_to_dotify?).and_return true # stub dotify file exist check
        dot.linked?.should == true
      end
      it "should return false if one or more checks fail" do
        dot.stub(:linked_to_dotify?).and_return false # stub dotify file exist check
        dot.linked?.should == false
      end
    end

    describe Dot, "#symlink" do
      let!(:dot) { Dot.new(".symlinked") }
      it "should return the symlink for the file" do
        File.should_receive(:readlink).with(dot.dotfile).once
        dot.symlink
      end
      it "should return NoSymlink if error or no symlink" do
        File.stub(:readlink).with(dot.dotfile).and_raise(StandardError)
        expect { dot.symlink }.not_to raise_error
        dot.symlink.should == NoSymlink
      end
    end

    describe "inspecting dot" do
      it "should display properly" do
        Dot.new(".zshrc").inspect.should == "#<Dotify::Dot filename: '.zshrc' linked: false>"
        bash = Dot.new(".bashrc")
        bash.stub(:linked?).and_return true
        bash.inspect.should == "#<Dotify::Dot filename: '.bashrc' linked: true>"

      end
    end

  end
end
