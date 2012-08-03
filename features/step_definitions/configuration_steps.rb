Then /^Dotify should have default configuration$/ do
  Dotify::Config.editor.should == 'vim'
  Dotify::Config.ignore(:dotify).should == %w[.DS_Store .git .gitmodule]
  Dotify::Config.ignore(:dotfiles).should == %w[.DS_Store .Trash .dropbox .dotify]
end

Then /^Dotify\'s editor should be "([^"]*)"/ do |editor|
  Dotify::Config.instance_variable_set("@hash", nil)
  Dotify::Config.editor.should == editor
end
