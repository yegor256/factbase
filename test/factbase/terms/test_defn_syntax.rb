# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/undef'
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

  def test_defn_on_empty_factbase
    fn = :_defn_empty_factbase
    Factbase::Undef.new([fn]).evaluate(nil, [], Factbase.new)
    fb = Factbase.new
    fb.query("(defn #{fn} \"true\")").each(fb).to_a
    assert(Factbase::Term.private_method_defined?(fn))
    fb.insert.a = 1
    assert_equal(1, fb.query("(#{fn})").each(fb).count)
  ensure
    Factbase::Undef.new([fn]).evaluate(nil, [], Factbase.new)
  end
end
