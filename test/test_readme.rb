# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/factbase'
require_relative '../lib/factbase/term'
require_relative 'test__helper'

# Test for the README.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestReadme < Factbase::Test
  def test_every_documented_term_exists
    term = Factbase::Term.new(:always, [])
    known = term.instance_variable_get(:@terms).keys.map(&:to_s)
    File.readlines(File.join(__dir__, '../README.md')).each do |line|
      next unless line.start_with?('* `(')
      op = line[4..].split(/[\s)`]/).first
      assert(
        known.include?(op) || term.respond_to?(op.to_sym, true),
        "The term '#{op}' is documented in README.md, but does not exist"
      )
    end
  end

  def test_counts_insert_in_tallied_example
    assert_equal(
      1,
      File.read(File.join(__dir__, '../README.md')).scan(/^```ruby\n(.*?)^```/m).flatten
        .find { |b| b.include?('Factbase::Tallied') }
        .then { |code| instance_eval("#{code}\nchurn.inserted", __FILE__, __LINE__) },
      'insert in the Tallied example of README.md is not counted'
    )
  end
end
