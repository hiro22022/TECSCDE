require "bundler/gem_tasks"
require "rake/clean"
require "rdoc/task"
task :default => :test

CLEAN.concat(FileList["lib/tecsgen/core/*.tab.rb"])
CLEAN.concat(FileList["lib/tecsgen/core/*.log"])

desc "Generate files"
task :generate => [:bnf, :yydebug, :c_parser]

task :bnf => ["lib/tecsgen/core/bnf.tab.rb"]
task :yydebug => ["lib/tecsgen/core/bnf-deb.tab.rb"]
task :c_parser => ["lib/tecsgen/core/C_parser.tab.rb"]

file "lib/tecsgen/core/bnf-deb.tab.rb" => ["lib/tecsgen/core/bnf.y.rb"] do |t|
  sh "bundle exec racc -O #{t.name}.log -v -g -o #{t.name} #{t.prerequisites.join(" ")}"
end

rule ".tab.rb" => [".y.rb"] do |t|
  sh "bundle exec racc -O #{t.name}.log -v -o #{t.name} #{t.source}"
end

RDoc::Task.new do |rdoc|
  rdoc.main = "README.md"
  rdoc.rdoc_files.include("README.md", "README.ja.md", "lib/**/*.rb")
end

