# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Test for unique term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/concat'

class TestConcat < Factbase::Test
  def test_concat
    t = Factbase::Concat.new([42, 'hi', 3.14, :hey, Time.now])
    s = t.evaluate(fact, [], Factbase.new)
    assert(s.start_with?('42hi3.14'))
  end

  def test_concat_empty
    t = Factbase::Concat.new([])
    assert_equal('', t.evaluate(fact, [], Factbase.new))
  end
end
