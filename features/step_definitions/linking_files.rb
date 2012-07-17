Given /^the following files are in home:$/i do |table|
  @files_to_link = table.raw.flatten
  @files_to_link.each { |file| `touch #{Dotify::Config.home(file)}` }
end

Given /^(.*) does not exist in (home|dotify)$/i do |file, location|
  location = location == 'home' ? :home : :path
  puts `rm -rf #{Dotify::Config.send(location, file)}`
end

When /^they get linked by Dotify$/ do
  @files_to_link.each { |file| Dotify::Dot.new(file).link }
end

Then /^they are all linked to the dotify path$/i do
  @files_to_link.each do |file|
    File.exists?(Dotify::Config.path(file)).should == true
    File.readlink(Dotify::Config.home(file)).should == Dotify::Config.path(file)
  end
end

Then /^\.(\S*) should exist in (home|dotify)$/ do |file, location|
  where = location == "home" ? :home : :path
  File.exists?(Dotify::Config.send(where, "." + file)).should == true
end
