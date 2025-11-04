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

  # @todo #302:30min Remove the _arithmetic method.
  #  Currently, we use it because we are required to inject all thesse methods into Factbase::Term.
  #  But we have Factbase::Arithmetic class for arithmetic operations.
  #  When all the 'math' terms will use from Factbase::Arithmetic, we can remove this method.
  def _arithmetic(op, fact, maps, fb); end
end
