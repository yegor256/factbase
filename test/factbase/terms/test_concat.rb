# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/concat'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

class TestConcat < Factbase::Test
  def test_concat
    assert(
      Factbase::Concat.new([42, 'hi', 3.14, :hey, Time.now]).evaluate(
        fact, [],
        Factbase.new
      ).start_with?('42hi3.14')
    )
  end

  def test_concat_empty
    assert_equal('', Factbase::Concat.new([]).evaluate(fact, [], Factbase.new))
  end

  def test_concat_all_values_of_a_property
    fb = Factbase.new
    f = fb.insert
    f.foo = 'a'
    f.foo = 'b'
    assert_equal('ab', fb.query('(as z (concat foo))').each.to_a.first['z'].first)
  end

  def test_concats_time_in_iso
    seed = Random.new_seed
    rnd = Random.new(seed)
    t = Time.at(rnd.rand(0..2_000_000_000), rnd.rand(1..999_999), :usec, in: 'UTC')
    assert_equal(
      "at #{t.iso8601(9)}", Factbase::Concat.new(['at ', :t]).evaluate(fact('t' => t), [], Factbase.new),
      "time #{t.inspect} was not concatenated in ISO 8601, seed #{seed}"
    )
  end
end
