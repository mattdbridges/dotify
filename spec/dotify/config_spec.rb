require 'spec_helper'
require 'dotify/errors'
require 'dotify/config'

describe Dotify::Config do
  describe Dotify::Config, "#installed?" do
    it "should return false if Dotify has not been setup" do
      File.should_receive(:directory?).with(File.join(Dotify::Config.home, Dotify::Config.dirname)).and_return(false)
      Dotify::Config.installed?.should == false
    end
    it "should return true if Dotify has been setup" do
      File.should_receive(:directory?).with(File.join(Dotify::Config.home, Dotify::Config.dirname)).and_return(true)
      Dotify::Config.installed?.should == true
    end
  end
  describe "options" do
    before do
      Dotify::Config.stub(:config)  do
        { :ignore => { :dotfiles => %w[.gemrc], :dotify => %w[.gitmodule] } }
      end
    end
    it "should be able to show the home path" do
      Dotify::Config.home.should == Thor::Util.user_home
    end
    it "should be able to show the dotify path" do
      Dotify::Config.path.should == File.join(Dotify::Config.home, '.dotify')
    end
    it "should set a default editor" do
      Dotify::Config.editor.should == Dotify::Config::EDITOR
    end
    it "should allow a custom editor" do
      Dotify::Config.stub(:config)  do
        { :editor => 'subl' }
      end
      Dotify::Config.editor.should == 'subl'
    end
  end

  describe Dotify::Config, "#file" do
    it "should return the right page" do
      Dotify::Config.stub(:home).and_return('/tmp')
      Dotify::Config.file.should == '/tmp/.dotrc'
    end
  end

  describe "ignore files" do
    before do
      Dotify::Config.stub(:config)  do
        { :ignore => { :dotfiles => %w[.gemrc], :dotify => %w[.gitmodule] } }
      end
    end
    it "should have a default set of dotfiles" do
      Dotify::Config.stub(:config).and_return({})
      Dotify::Config.ignore(:dotify).should include '.git'
      Dotify::Config.ignore(:dotify).should include '.gitmodule'
      Dotify::Config.ignore(:dotfiles).should include '.dropbox'
      Dotify::Config.ignore(:dotfiles).should include '.Trash'
      Dotify::Config.ignore(:dotfiles).should include '.dotify'
    end
    it "should retrieve the list of dotfiles to ignore in the home directory" do
      Dotify::Config.ignore(:dotfiles).should include '.gemrc'
    end
    it "should retrieve the list of dotify files to ignore" do
      Dotify::Config.ignore(:dotify).should include '.gitmodule'
    end
  end
end
