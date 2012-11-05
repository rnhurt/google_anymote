#!/usr/bin/env rake
require "bundler/gem_tasks"

desc "Generate documentation"
task :doc => :yard

desc "Generated YARD documentation"
task :yard do
  require "yard"

  opts = []
  opts.push("--protected")
  opts.push("--no-private")
  opts.push("--private")
  opts.push("--title", "GoogleAnymote")

  YARD::CLI::Yardoc.run(*opts)
end