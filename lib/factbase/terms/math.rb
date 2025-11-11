# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'

# Math terms.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
module Factbase::Math
  def eq(fact, maps, fb)
    _cmp(:==, fact, maps, fb)
  end

  def lt(fact, maps, fb)
    _cmp(:<, fact, maps, fb)
  end

  def gt(fact, maps, fb)
    _cmp(:>, fact, maps, fb)
  end

  def lte(fact, maps, fb)
    _cmp(:<=, fact, maps, fb)
  end

  def gte(fact, maps, fb)
    _cmp(:>=, fact, maps, fb)
  end

  def _cmp(op, fact, maps, fb)
    assert_args(2)
    lefts = _values(0, fact, maps, fb)
    return false if lefts.nil?
    rights = _values(1, fact, maps, fb)
    return false if rights.nil?
    lefts.any? do |l|
      l = l.floor if l.is_a?(Time) && op == :==
      rights.any? do |r|
        r = r.floor if r.is_a?(Time) && op == :==
        l.send(op, r)
      end
    end
  end
end
