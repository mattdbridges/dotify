require 'dotify/cli/listing'
require 'thor/shell/color'
require 'spec_helper'

module Dotify
  module CLI
    describe Listing do
      let(:collection) do
        [
          LinkedDot.new(".dotrc"),
          LinkedDot.new(".gitconfig"),
          LinkedDot.new(".vimrc"),
          LinkedDot.new(".zshrc")
        ]
      end
      let(:listing) { Listing.new(collection, { :force => true }) }
      subject { listing }

      before { subject.stub(:inform) } # do not output anything

      describe "attributes" do
        its(:collection) { should == collection }
        its(:options) { should == { :force => true } }
      end

      describe "file counting" do
        before { subject.collection.stub(:count).and_return 3 }
        its(:count) { should == 3 }
      end
      it "should call say the right number of times" do
        Thor::Shell::Color.any_instance.should_receive(:say).exactly(subject.collection.size).times
        subject.write
      end
      describe "writing the output" do
        before do
          subject.stub(:collection).and_return []
          subject.should_receive(:inform).once
        end
        it { subject.write }
      end
    end
  end
end
