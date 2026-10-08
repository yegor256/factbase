# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase'
require_relative '../../lib/factbase/accum'
require_relative '../../lib/factbase/rules'
require_relative '../../lib/factbase/tee'

require_relative '../test__helper'

# Test.
class TestNoConversion < Factbase::Test
  def test_does_not_claim_implicit_array_conversion
    fact = self.fact
    facts.each do |item|
      refute_respond_to(item, :to_ary)
      assert_equal([item], [item].flatten)
    end
    assert_equal([[fact, nil]], [fact].map { |one, two| [one, two] })
  end

  def test_converts_to_text_through_to_s
    facts.each do |item|
      refute_respond_to(item, :to_str)
      assert_equal(item.to_s, [item].join)
    end
  end

  private

  def fact
    f = Factbase.new.insert
    f.foo = 1
    f
  end

  def facts
    fact = self.fact
    [
      fact,
      Factbase::Accum.new(fact, {}, false),
      Factbase::Tee.new(fact, {}),
      Factbase::Rules::Fact.new(fact, nil, Factbase.new)
    ]
  end
end
