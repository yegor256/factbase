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
end
