# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/cached/cached_factbase'
require_relative '../../lib/factbase/impatient'
require_relative '../../lib/factbase/indexed/indexed_factbase'
require_relative '../../lib/factbase/inv'
require_relative '../../lib/factbase/logged'
require_relative '../../lib/factbase/pre'
require_relative '../../lib/factbase/rules'
require_relative '../../lib/factbase/sync/sync_factbase'
require_relative '../../lib/factbase/tallied'
require_relative '../test__helper'

# Test for Enumerated.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestEnumerated < Factbase::Test
  def test_returns_an_enumerator_from_each_without_a_block_on_every_decorator
    [
      Factbase::IndexedFactbase.new(Factbase.new),
      Factbase::CachedFactbase.new(Factbase.new),
      Factbase::SyncFactbase.new(Factbase.new),
      Factbase::Logged.new(Factbase.new, Loog::NULL),
      Factbase::Tallied.new(Factbase.new),
      Factbase::Impatient.new(Factbase.new),
      Factbase::Rules.new(Factbase.new, '(always)'),
      Factbase::Inv.new(Factbase.new) { |_p, _v| true },
      Factbase::Pre.new(Factbase.new) { |_f, _fbt| true }
    ].each do |fb|
      4.times { fb.insert.x = 1 }
      assert_kind_of(Enumerator, fb.each, "#{fb.class} didn't return an enumerator")
      assert_equal(4, fb.each.to_a.size, "#{fb.class} didn't enumerate all facts")
      assert_equal(4, fb.each { |_f| true }, "#{fb.class} didn't count the facts with a block")
    end
  end
end
