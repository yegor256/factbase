# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/to_string'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for 'to_string' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestToString < Factbase::Test
  def test_to_str
    assert_equal('String', Factbase::ToString.new([Time.now]).evaluate(fact, [], Factbase.new).class.to_s)
  end

  def test_prints_time_with_fraction_in_iso
    seed = Random.new_seed
    rnd = Random.new(seed)
    t = Time.at(rnd.rand(0..2_000_000_000), rnd.rand(1..999_999), :usec, in: 'UTC')
    assert_equal(
      t.iso8601(9), Factbase::ToString.new([:t]).evaluate(fact('t' => t), [], Factbase.new),
      "time #{t.inspect} was not printed in ISO 8601 with its fraction, seed #{seed}"
    )
  end

  def test_prints_whole_time_in_iso_without_fraction
    seed = Random.new_seed
    t = Time.at(Random.new(seed).rand(0..2_000_000_000), in: 'UTC')
    assert_equal(
      t.iso8601, Factbase::ToString.new([:t]).evaluate(fact('t' => t), [], Factbase.new),
      "time #{t.inspect} was not printed in ISO 8601, seed #{seed}"
    )
  end

  def test_prints_time_in_utc
    seed = Random.new_seed
    t = Time.at(Random.new(seed).rand(0..2_000_000_000), in: '+03:00')
    assert_equal(
      t.utc.iso8601, Factbase::ToString.new([t]).evaluate(fact, [], Factbase.new),
      "time #{t.inspect} was not printed in UTC, seed #{seed}"
    )
  end

  def test_reads_back_printed_time
    seed = Random.new_seed
    rnd = Random.new(seed)
    fb = Factbase.new
    fb.insert.t = Time.at(rnd.rand(0..2_000_000_000), rnd.rand(1..999_999), :usec)
    assert_equal(
      1, fb.query('(eq (to_time (to_string t)) t)').each.to_a.size,
      "printed time was not read back as the same time, seed #{seed}"
    )
  end
end
