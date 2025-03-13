# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'

# Meta terms.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
module Factbase::Meta
  def exists(fact, _maps, _fb)
    assert_args(1)
    !_by_symbol(0, fact).nil?
  end

  def absent(fact, _maps, _fb)
    assert_args(1)
    _by_symbol(0, fact).nil?
  end

  def size(fact, _maps, _fb)
    assert_args(1)
    v = _by_symbol(0, fact)
    return 0 if v.nil?
    return 1 unless v.respond_to?(:to_a)
    v.size
  end

  def type(fact, _maps, _fb)
    assert_args(1)
    v = _by_symbol(0, fact)
    return 'nil' if v.nil?
    v = v[0] if v.respond_to?(:each) && v.size == 1
    v.class.to_s
  end

  def nil(fact, maps, fb)
    assert_args(1)
    _values(0, fact, maps, fb).nil?
  end

  def many(fact, maps, fb)
    assert_args(1)
    v = _values(0, fact, maps, fb)
    !v.nil? && v.size > 1
  end

  def one(fact, maps, fb)
    assert_args(1)
    v = _values(0, fact, maps, fb)
    !v.nil? && v.size == 1
  end
end
