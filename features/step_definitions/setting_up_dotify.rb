Given /^Dotify is not setup$/ do
  %x[rm -rf #{File.join(ENV["HOME"], ".dotify")}]
end

Given /^Dotify is setup$/i do
  %x[
    mkdir -p #{Dotify::Config.path}
    touch #{Dotify::Config.home(".dotrc")}
  ]
end
