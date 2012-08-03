Given /^the following files are in home:$/i do |table|
  @files_to_link = table.raw.flatten
  @files_to_link.each { |file| `touch #{Dotify::Config.home(file)}` }
end

Given /^(.*) does not exist in (home|dotify)$/i do |file, location|
  location = location == 'home' ? :home : :path
  %x[rm -rf #{Dotify::Config.send(location, file)}]
end

Then /^"(.*?)" should be linked to Dotify$/ do |file|
  File.exists?(Dotify::Config.path(file)).should == true
  File.readlink(Dotify::Config.home(file)).should == Dotify::Config.path(file)
end

Then /^"(.*?)" should not be linked to Dotify$/ do |orig_file|
  file = Dotify::Dot.new(orig_file)
  if File.symlink?(orig_file)
    file.symlink.should_not eq file.dotify
  end
end
