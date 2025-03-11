# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'

# Aliases terms.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
module Factbase::Term::Aliases
  def as(fact, maps, fb)
    assert_args(2)
    a = @operands[0]
    raise "A symbol expected as first argument of 'as'" unless a.is_a?(Symbol)
    vv = _values(1, fact, maps, fb)
    vv&.each { |v| fact.send(:"#{a}=", v) }
    true
  end

  def join(fact, maps, fb)
    assert_args(2)
    jumps = @operands[0]
    raise "A string expected as first argument of 'join'" unless jumps.is_a?(String)
    jumps = jumps.split(',')
      .map(&:strip)
      .map { |j| j.split('<=').map(&:strip) }
      .map { |j| j.size == 1 ? [j[0], j[0]] : j }
    term = @operands[1]
    raise "A term expected, but '#{term}' provided" unless term.is_a?(Factbase::Term)
    subset = fb.query(term, maps).each(fb, fact).to_a
    subset.each do |s|
      jumps.each do |to, from|
        s[from]&.each do |v|
          fact.send(:"#{to}=", v)
        end
      end
    end
    true
  end
end
