# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'

# Debug terms.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
module Factbase::Term::Debug
  def traced(fact, maps, _fb)
    assert_args(1)
    t = @operands[0]
    raise "A term expected, but '#{t}' provided" unless t.is_a?(Factbase::Term)
    r = t.evaluate(fact, maps)
    puts "#{self} -> #{r}"
    r
  end
end
