require "rake/clean"
require "bundler/gem_tasks"
task :default => :test

CLEAN.concat(FileList["lib/tecsgen/core/*.tab.rb"])
CLEAN.concat(FileList["lib/tecsgen/core/*.log"])

desc "Generate files"
task :generate => [:bnf, :yydebug, :c_parser]

desc "Generate lib/tecsgen/core/bnf.tab.rb"
task :bnf => ["lib/tecsgen/core/bnf.tab.rb"]

desc "Generate lib/tecsgen/core/bnf-deb.tab.rb"
task :yydebug => ["lib/tecsgen/core/bnf-deb.tab.rb"]

desc "Generate lib/tecsgen/core/C_parser.tab.rb"
task :c_parser => ["lib/tecsgen/core/C_parser.tab.rb"]

file "lib/tecsgen/core/bnf-deb.tab.rb" => ["lib/tecsgen/core/bnf.y.rb"] do |t|
  sh "bundle exec racc -O #{t.name}.log -v -g -o #{t.name} #{t.prerequisites.join(" ")}"
end

rule ".tab.rb" => [".y.rb"] do |t|
  sh "bundle exec racc -O #{t.name}.log -v -o #{t.name} #{t.source}"
end
