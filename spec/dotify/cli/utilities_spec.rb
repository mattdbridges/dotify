require 'spec_helper'
require 'dotify/cli/utilities'
require 'rspec/matchers/built_in/yield'
require 'thor/actions'


module Dotify
  module CLI
    class FakeCli
      include CLI::Utilities
      def initialize; end
      def inform(*args); end
    end

    describe Utilities do
      let(:cli) { FakeCli.new }
      subject { cli }

      describe "instance and class methods" do
        it { should respond_to :inform }
        it { should respond_to :run_if_installed }
        it(:class) { should respond_to :inform }
        it(:class) { should respond_to :run_if_installed }
      end

      describe Utilities, "#say" do
        it "should pass to Thor::Shell::Basic with right params" do
          Thor::Shell::Color.any_instance.should_receive(:say).with(" ** something", :blue).once
          subject.say "something", :blue
        end
      end

      describe Utilities, "#caution" do
        it "should pass to Thor::Shell::Basic with right params" do
          subject.should_receive(:say).with("something", :red)
          subject.caution "something"
        end
      end

      describe Utilities, "#run_if_installed" do
        it "should yield if Dotify is installed" do
          Config.stub(:installed?).and_return true
          expect { |b| subject.run_if_installed(&b) }.to yield_control
        end
        it "should not yield if Dotify is not installed" do
          Config.stub(:installed?).and_return false
          expect { |b| subject.run_if_installed(&b) }.not_to yield_control
        end
        it "should inform user if Dotify is not installed" do
          Config.stub(:installed?).and_return false
          subject.should_receive(:inform).once
          subject.run_if_installed { }
        end
        it "should not inform user if Dotify is not installed" do
          Config.stub(:installed?).and_return false
          subject.should_not_receive(:inform)
          subject.run_if_installed(false) { }
        end
      end

      describe Utilities, "#run_if_not_installed" do
        it "should yield if Dotify is installed" do
          Config.stub(:installed?).and_return false
          expect { |b| subject.run_if_not_installed(&b) }.to yield_control
        end
        it "should not yield if Dotify is not installed" do
          Config.stub(:installed?).and_return true
          expect { |b| subject.run_if_not_installed(&b) }.not_to yield_control
        end
        it "should inform user if Dotiyf is not installed" do
          Config.stub(:installed?).and_return true
          subject.should_receive(:inform).once
          subject.run_if_not_installed { }
        end
        it "should not inform user if Dotify is not installed" do
          Config.stub(:installed?).and_return true
          subject.should_not_receive(:inform)
          subject.run_if_installed(false) { }
        end
      end

    end
  end
end
