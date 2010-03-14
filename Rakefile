begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "swfmill_ruby"
    gemspec.author = "tmtysk"
    gemspec.email = "tmtysk@gmail.com"
    gemspec.summary = "utility-classes to use Swfmill(http://swfmill.org) via Ruby."
    gemspec.description = File.read("README")
    gemspec.files = Rake::FileList.new("lib/**/*.rb", "[A-Z]*", "doc/**/*.html", "sample/**/*")
    gemspec.homepage = "http://github.com/tmtysk/swfmill_ruby"
    gemspec.add_dependency("rmagick", ">= 2.8.0")
    gemspec.add_dependency("libxml-ruby", ">= 0.9.7")
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end
