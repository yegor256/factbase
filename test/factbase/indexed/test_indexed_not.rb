# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/taped'
require_relative '../../../lib/factbase/indexed/indexed_term'
require_relative '../../../lib/factbase/indexed/indexed_not'

# Indexed term 'not' test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestIndexedNot < Factbase::Test
  def test_predicts_on_not
    term = Factbase::Term.new(:not, [Factbase::Term.new(:eq, [:foo, 42])])
    idx = {}
    term.redress!(Factbase::IndexedTerm, idx:)
    maps = Factbase::Taped.new([{ 'foo' => [42] }, { 'bar' => [7], 'foo' => [22, 42] }, { 'foo' => [22] }])
    n = term.predict(maps, nil, {})
    assert_equal(1, n.size)
    assert_kind_of(Factbase::Taped, n)
  end

  def test_predicts_on_not_returns_nil
    term = Factbase::Term.new(:not, [Factbase::Term.new(:some, [:bar, 22])])
    idx = {}
    term.redress!(Factbase::IndexedTerm, idx:)
    maps = Factbase::Taped.new([{ 'foo' => [21] }])
    n = term.predict(maps, nil, {})
    assert_nil(n)
  end
end
