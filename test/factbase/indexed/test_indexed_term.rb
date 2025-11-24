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
  def test_predicts_on_others
    term = Factbase::Term.new(:boom, [])
    idx = {}
    term.redress!(Factbase::IndexedTerm, idx:)
    maps = Factbase::Taped.new([{ 'foo' => [42] }, { 'alpha' => [] }, {}])
    n = term.predict(maps, nil, {})
    assert_nil(n)
  end
end
