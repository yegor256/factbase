# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'yaml'
require_relative 'test__helper'

# Test for the gemspec.
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestGemspec < Factbase::Test
  def test_refuses_ruby_older_than_rubocop_target
    seed = Random.new_seed
    rnd = Random.new(seed)
    target = Gem::Version.new(
      YAML.safe_load_file(File.join(__dir__, '../.rubocop.yml')).dig('AllCops', 'TargetRubyVersion').to_s
    )
    version = Gem::Version.new("#{target.segments[0]}.#{rnd.rand(0...target.segments[1])}.#{rnd.rand(0..9)}")
    refute(
      Gem::Specification.load(File.join(__dir__, '../factbase.gemspec')).required_ruby_version.satisfied_by?(version),
      "gemspec accepts Ruby #{version}, older than #{target} that the code needs, seed #{seed}"
    )
  end

  def test_accepts_ruby_of_rubocop_target
    target = Gem::Version.new(
      YAML.safe_load_file(File.join(__dir__, '../.rubocop.yml')).dig('AllCops', 'TargetRubyVersion').to_s
    )
    assert(
      Gem::Specification.load(File.join(__dir__, '../factbase.gemspec')).required_ruby_version.satisfied_by?(target),
      "gemspec refuses Ruby #{target} that the code is written for"
    )
  end
end
