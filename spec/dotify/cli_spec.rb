require 'spec_helper'
require 'dotify'
require 'thor'

module Dotify
  describe CLI do
    let!(:cli) { CLI.new }
    before do
      Dotify.stub(:installed?).and_return true
      vimrc = Dot.new('.zshrc')
      vimrc.stub(:linked?).and_return(true)
      bash_profile = Dot.new('.bash_profile')
      bash_profile.stub(:linked?).and_return(true)
      gitconfig = Dot.new('.gitconfig')
      gitconfig.stub(:linked?).and_return(false)
      zshrc = Dot.new('.zshrc')
      zshrc.stub(:linked?).and_return(false)
      Filter.stub(:home).and_return([vimrc, bash_profile, gitconfig, zshrc])
    end

    describe CLI, "#edit" do
      let(:dot) { double('dot', :linked? => true, :dotify => '/tmp/dotify/.vimrc') }
      before do
        Dot.stub(:new).and_return(dot)
        cli.stub(:exec)
      end
      it "should open the editor with the passed file" do
        cli.should_receive(:exec).with([Config.editor, dot.dotify].join(" "))
        cli.edit('.vimrc')
      end
      it "should  the editor with the passed file" do
        cli.should_receive(:save)
        cli.stub(:options).and_return({ :save => true })
        cli.edit '.vimrc'
      end
      it "should not edit the file if it has not been linked" do
        dot.stub(:linked?).and_return false
        cli.should_receive(:say).with("'#{dot}' has not been linked by Dotify. Please run `dotify link #{dot}` to edit this file.", :blue)
        cli.edit('.vimrc')
      end
    end

    describe CLI, "#link" do
      before do
        cli.stub(:file_action)
      end
      it "should loop through all unlinked files" do
        Dotify.collection.should_receive(:unlinked).and_return Dotify.collection.reject(&:linked?)
        cli.link
      end
      it "should call link_file on the right files" do
        cli.should_receive(:file_action).exactly(Dotify.collection.unlinked.size).times
        cli.link
      end
      it "should relink all of the files located in Dotify" do
        Dotify.collection.should_not_receive(:unlinked)
        Dotify.collection.should_receive(:linked).and_return []
        cli.stub(:options).and_return({ :relink => true })
        cli.link
      end
      it "attempt to link one single file" do
        cli.should_receive(:file_action).with(:link, an_instance_of(Dot), {})
        cli.link('.vimrc')
      end
      it "should output a warning if Dotify is not installed" do
        Dotify.stub(:installed?).and_return false
        cli.should_receive(:not_setup_warning).once
        cli.link
      end
    end

    describe CLI, "#unlink" do
      before do
        cli.stub(:file_action)
      end
      it "should loop through all unlinked files" do
        Dotify.collection.should_receive(:linked).and_return Dotify.collection.select(&:linked?)
        cli.unlink
      end
      it "should call CLI#unlink_file the right number of times" do
        cli.should_receive(:file_action).exactly(Dotify.collection.linked.size).times
        cli.unlink
      end
      it "attempt to link one single file" do
        cli.should_receive(:file_action).with(:unlink, an_instance_of(Dot), {})
        cli.unlink('.vimrc')
      end
      it "should output a warning if Dotify is not installed" do
        Dotify.stub(:installed?).and_return false
        cli.should_receive(:not_setup_warning).once
        cli.unlink
      end
    end
  end
end
