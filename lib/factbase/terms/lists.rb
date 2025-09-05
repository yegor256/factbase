# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'

# Lists management.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
module Factbase::Lists
  def sorted(_fact, _maps, _fb)
    true
  end

  def sorted_predict(maps, fb, params)
    assert_args(2)
    prop = @operands[0]
    raise "A symbol is expected as first argument of 'sorted'" unless prop.is_a?(Symbol)
    term = @operands[1]
    raise "A term is expected, but '#{term}' provided" unless term.is_a?(Factbase::Term)
    fb.query(term, maps).each(fb, params).to_a
      .reject { |m| m[prop].nil? }
      .sort_by { |m| m[prop].first }
      .map { |m| m.all_properties.to_h { |k| [k, m[k]] } }
  end

  def inverted(_fact, _maps, _fb)
    true
  end

  def inverted_predict(maps, fb, params)
    assert_args(1)
    term = @operands[0]
    raise "A term is expected, but '#{term}' provided" unless term.is_a?(Factbase::Term)
    fb.query(term, maps).each(fb, params).to_a
      .reverse
      .map { |m| m.all_properties.to_h { |k| [k, m[k]] } }
  end

  def head(_fact, _maps, _fb)
    true
  end

  def head_predict(maps, fb, params)
    assert_args(2)
    max = @operands[0]
    raise "An integer is expected as first argument of 'sorted'" unless max.is_a?(Integer)
    term = @operands[1]
    raise "A term is expected, but '#{term}' provided" unless term.is_a?(Factbase::Term)
    fb.query(term, maps).each(fb, params).to_a
      .take(max)
      .map { |m| m.all_properties.to_h { |k| [k, m[k]] } }
  end
end
