# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'os'
require 'qbash'
require 'rake'
require 'rake/clean'
require 'rubygems'
require 'shellwords'

def name
  @name ||= File.basename(Dir['*.gemspec'].first, '.*')
end

def version
  Gem::Specification.load(Dir['*.gemspec'].first).version
end

task default: %i[clean test picks rubocop yard]

require 'rake/testtask'
desc 'Run all unit tests'
Rake::TestTask.new(:test) do |test|
  Rake::Cleaner.cleanup_files(['coverage'])
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.warning = true
  test.verbose = false
end

desc 'Run them via Ruby, one by one'
task :picks do
  next if OS.windows?
  %w[text lib].each do |d|
    Dir["#{d}/**/*.rb"].each do |f|
      qbash("bundle exec ruby #{Shellwords.escape(f)}", log: $stdout)
    end
  end
end

require 'yard'
desc 'Build Yard documentation'
YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb']
end

require 'rubocop/rake_task'
desc 'Run RuboCop on all directories'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.fail_on_error = true
end

desc 'Benchmark them all'
task :benchmark do
  require_relative 'lib/factbase'
  fb = Factbase.new
  require_relative 'lib/factbase/cached/cached_factbase'
  fb = Factbase::CachedFactbase.new(fb)
  require_relative 'lib/factbase/indexed/indexed_factbase'
  fb = Factbase::IndexedFactbase.new(fb)
  require_relative 'lib/factbase/sync/sync_factbase'
  fb = Factbase::SyncFactbase.new(fb)
  require 'benchmark'
  Benchmark.bm(60) do |b|
    Dir['benchmark/bench_*.rb'].each do |f|
      require_relative f
      Kernel.send(File.basename(f).gsub(/\.rb$/, '').to_sym, b, fb)
    end
  end
end
