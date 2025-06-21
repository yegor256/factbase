# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'

# String terms.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
module Factbase::Strings
  def concat(fact, maps, fb)
    (0..(@operands.length - 1)).map { |i| _values(i, fact, maps, fb)&.first }.join
  end

  def sprintf(fact, maps, fb)
    fmt = _values(0, fact, maps, fb)[0]
    ops = (1..(@operands.length - 1)).map { |i| _values(i, fact, maps, fb)&.first }
    format(*([fmt] + ops))
  end

  def matches(fact, maps, fb)
    assert_args(2)
    str = _values(0, fact, maps, fb)
    return false if str.nil?
    raise 'Exactly one string expected' unless str.size == 1
    re = _values(1, fact, maps, fb)
    raise 'Regexp is nil' if re.nil?
    raise 'Exactly one regexp expected' unless re.size == 1
    str[0].to_s.match?(re[0])
  end
end
