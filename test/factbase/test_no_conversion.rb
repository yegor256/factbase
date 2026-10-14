# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase'
require_relative '../../lib/factbase/accum'
require_relative '../../lib/factbase/cached/cached_fact'
require_relative '../../lib/factbase/indexed/indexed_fact'
require_relative '../../lib/factbase/inv'
require_relative '../../lib/factbase/logged'
require_relative '../../lib/factbase/rules'
require_relative '../../lib/factbase/tallied'
require_relative '../../lib/factbase/tee'

require_relative '../test__helper'

# Test.
class TestNoConversion < Factbase::Test
  def test_does_not_claim_implicit_array_conversion
    fact = self.fact
    facts.each do |item|
      refute_respond_to(item, :to_ary)
      assert_equal([item], [item].flatten)
      assert_equal([item], Array(item))
    end
    assert_equal([[fact, nil]], [fact].map { |one, two| [one, two] })
  end

  def test_converts_to_text_through_to_s
    facts.each do |item|
      refute_respond_to(item, :to_str)
      assert_equal(item.to_s, [item].join)
    end
  end

  def test_rejects_conversion_protocols_and_keeps_property_access
    protocols = %i[to_a to_ary to_str to_hash to_io to_proc to_int]
    facts.each do |item|
      protocols.each do |method|
        refute_respond_to(item, method)
        assert_raises(NoMethodError) { item.public_send(method) }
      end
      assert_respond_to(item, :foo)
      assert_equal(1, item.foo)
      assert_equal([1], item['foo'])
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
      Factbase::Rules::Fact.new(fact, nil, Factbase.new),
      Factbase::CachedFact.new(fact, {}),
      Factbase::IndexedFact.new(fact, {}, Set.new),
      Factbase::Inv::Fact.new(fact, nil),
      Factbase::Logged::Fact.new(fact),
      Factbase::Tallied::Fact.new(fact, Factbase::Churn.new)
    ]
  end
end
