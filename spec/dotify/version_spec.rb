require 'spec_helper'
require 'dotify/version'

module Dotify
  describe Version do
    describe "#to_s" do
      it "should equal the right number" do
        expect(Version.to_s).to eq(Dotify::VERSION)
      end
    end
    it "#run_check! should return the right version number" do
      VCR.use_cassette "version_check" do
        Version.version.should == '0.2.0'
      end
    end
    describe "#out_of_date?" do
      subject(:v) { Version.dup }
      context "out of date" do 
        before { def v.current?; false; end }
        its(:out_of_date?) { should == true }
      end
      context "up to date" do 
        before { def v.current?; true; end }
        its(:out_of_date?) { should == false }
      end
    end
    describe "#current?" do
      subject(:v) { Version.dup }
      context "when current" do 
        before do
          stub_const "Dotify::VERSION", '0.2.0'
          def subject.version; '0.1.9'; end
        end
        its(:current?) { should == false }
      end
      context "when current" do 
        before do
          stub_const "Dotify::VERSION", '0.2.0'
          def subject.version; '0.2.0'; end
        end
        its(:current?) { should == true }
      end
    end
    describe "#handle_error" do
      let(:error) { OpenStruct.new(:message => "Fake message", :backtrace => ["fake", "backtrace"]) }
      subject { Version.handle_error(error) }
      it { should =~ %r{Fake message} }
      it { should =~ %r{fake} }
      it { should =~ %r{backtrace} }
    end
  end
end
