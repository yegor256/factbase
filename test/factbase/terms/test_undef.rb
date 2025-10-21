# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/defn'
require_relative '../../../lib/factbase/terms/undef'

# Test for undef term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestUndef < Factbase::Test
  def test_undef_simple
    t = Factbase::Defn.new([:hello, 'self.to_s'])
    assert(t.evaluate(fact, [], Factbase.new))
    t = Factbase::Undef.new([:hello])
    assert(t.evaluate(fact, [], Factbase.new))
  end
end
