# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase'
require_relative '../../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestDefnSyntax < Factbase::Test
  def test_explains_a_body_that_is_not_ruby
    fb = Factbase.new
    fb.insert.foo = 1
    e =
      assert_raises(StandardError) do
        fb.query('(defn brk "1 +")').each.to_a
      end
    assert_includes(e.message, "Cannot define the term 'brk'", e.message)
  end
end
