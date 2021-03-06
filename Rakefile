require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'fileutils'

RSpec::Core::RakeTask.new(:spec)

desc 'Generate missing specs'
task :missing_specs do
  specs = Dir.glob("./lib/**/*.rb").map do |f|
    f.gsub(/\.\/lib(.*)\.rb/, "./spec\\1_spec.rb")
  end
  specs.each do |f|
    unless File.exist? f
      puts 'created: ' + f
      FileUtils.mkdir_p(File.dirname(f)) && FileUtils.touch(f)
    end
  end
end

desc 'Open a console with jsonapionify'
task :console do
  require 'jsonapionify'
  Pry.start
end

task :benchmark do
  require 'jsonapionify'
  toplevel = nil
  puts parse: Benchmark.realtime { toplevel = JSONAPIonify.parse(File.read('spec/fixtures/sample.json')) }
  puts validate: Benchmark.realtime { toplevel.validate }
  puts generate: Benchmark.realtime { toplevel.to_json(validate: false) }
end

desc 'Remove empty specs'
task :prune_specs do
  empty_specs = Dir.glob("./spec/**/*_spec.rb").select do |f|
    File.read(f).empty?
  end
  empty_specs.each do |f|
    FileUtils.rm f
  end
end

STATS_DIRECTORIES = [
  %w(Structure        lib/jsonapionify/structure),
  %w(Server           lib/jsonapionify/api),
  %w(Specs            spec),
].collect do |name, dir|
  [name, "#{File.dirname(Rake.application.rakefile_location)}/#{dir}"]
end.select { |name, dir| File.directory?(dir) }

desc "Report code statistics (KLOCs, etc)"
task :stats do
  require_relative './vendor/code_statistics'
  CodeStatistics.new(*STATS_DIRECTORIES).to_s
end

task :default => :spec
