# frozen_string_literal: true

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_factbase'
require_relative '../../../lib/factbase/indexed/indexed_term'
require_relative '../../../lib/factbase/taped'
require_relative '../../../lib/factbase/term'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Term test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedTerm < Factbase::Test
  def test_names_the_term_when_the_values_cannot_be_compared
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.insert.num = 5
    fb.insert.num = 'alpha'
    e = assert_raises(StandardError) { fb.query('(gt num 2)').each.to_a }
    assert_includes(e.message, '(gt num 2)', e.message)
  end

  def test_predicts_on_others
    term = Factbase::Term.new(:boom, [])
    term.redress!(Factbase::IndexedTerm, idx: {})
    assert_nil(term.predict(Factbase::Taped.new([{ 'foo' => [42] }, { 'alpha' => [] }, {}]), nil, {}))
  end
end
