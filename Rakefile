# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
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

def tail(args = ARGV)
  i = args.index('--')
  return '' if i.nil? || args[i + 1].nil?
  args[i..].join(' ')
end

require 'rake/testtask'
desc 'Run all unit tests'
Rake::TestTask.new(:test) do |test|
  Rake::Cleaner.cleanup_files(['coverage'])
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.warning = true
  test.verbose = false
  test.options = tail
end

desc 'Run them via Ruby, one by one'
task :picks do
  next if OS.windows?
  %w[test lib].each do |d|
    Dir["#{d}/**/*.rb"].each do |f|
      qbash("bundle exec ruby #{Shellwords.escape(f)}", stdout: $stdout, env: { 'PICKS' => 'yes' })
    end
  end
end

require 'yard'
desc 'Build Yard documentation'
YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb']
  t.options = ['--fail-on-warning']
end

require 'rubocop/rake_task'
desc 'Run RuboCop on all directories'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.fail_on_error = true
end

desc 'Benchmark them all'
task :benchmark, [:name] do |_t, args|
  bname = args[:name] || 'all'
  require_relative 'lib/factbase'
  require_relative 'lib/factbase/cached/cached_factbase'
  require_relative 'lib/factbase/indexed/indexed_factbase'
  require_relative 'lib/factbase/sync/sync_factbase'
  require 'benchmark'
  Benchmark.bm(60) do |b|
    fb = Factbase.new
    fb = Factbase::CachedFactbase.new(fb)
    fb = Factbase::IndexedFactbase.new(fb)
    fb = Factbase::SyncFactbase.new(fb)
    if bname == 'all'
      Dir['benchmark/bench_*.rb'].each do |f|
        require_relative f
        Kernel.send(File.basename(f).gsub(/\.rb$/, '').to_sym, b, fb)
      end
    else
      f = "benchmark/#{bname}.rb"
      require_relative f
      Kernel.send(File.basename(f).gsub(/\.rb$/, '').to_sym, b, fb)
    end
  end
end

# Run profiling on a benchmark and generate a flamegraph.
# To run this task, you need to have stackprof installed.
# https://github.com/tmm1/stackprof
# To run profiling for a specific benchmark you can run:
#   bundle exec rake flamegraph\[bench_slow_query\]
desc 'Profile a benchmark (e.g., flamegraph[bench_slow_query])'
task :flamegraph, [:name] do |_t, args|
  require 'stackprof'
  bname = args[:name] || 'all'
  puts "Starting profiling for '#{bname}'..." # rubocop:disable Lint/Debugger
  StackProf.run(mode: :cpu, out: 'stackprof-cpu-myapp.dump', raw: true) do
    Rake::Task['benchmark'].invoke(bname)
  end
  `stackprof --d3-flamegraph stackprof-cpu-myapp.dump > flamegraph.html`
end
