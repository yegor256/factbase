# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/taped'
require_relative '../../../lib/factbase/indexed/indexed_term'

# Term test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
# @todo #363:30min Introduce new test for indexed 'absent' term. We've moved the logic for prediction
#  'absent' term from IndexedTerm class to a separated IndexedAbsent class. But for some reason there's
#  no test for the term in this TestIndexedTerm. Let's introduce it and move to a separated test class like
#  it's done with TestIndexedOne.
class TestIndexedTerm < Factbase::Test
  # @todo #363:30min Move the test to a separated class. Since we've moved prediction of 'not' term
  #  to separated class IndexedNot, let's move this test to a separated test class too in order to be
  #  consistent with rule 'one class - one test class'
  def test_predicts_on_not
    term = Factbase::Term.new(:not, [Factbase::Term.new(:eq, [:foo, 42])])
    idx = {}
    term.redress!(Factbase::IndexedTerm, idx:)
    maps = Factbase::Taped.new([{ 'foo' => [42] }, { 'bar' => [7], 'foo' => [22, 42] }, { 'foo' => [22] }])
    n = term.predict(maps, nil, {})
    assert_equal(1, n.size)
    assert_kind_of(Factbase::Taped, n)
  end

  def test_predicts_on_others
    term = Factbase::Term.new(:boom, [])
    idx = {}
    term.redress!(Factbase::IndexedTerm, idx:)
    maps = Factbase::Taped.new([{ 'foo' => [42] }, { 'alpha' => [] }, {}])
    n = term.predict(maps, nil, {})
    assert_nil(n)
  end
end
