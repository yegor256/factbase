# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'

# Casting terms.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
module Factbase::Term::Casting
  def to_string(fact, maps)
    assert_args(1)
    vv = the_values(0, fact, maps)
    return nil if vv.nil?
    vv[0].to_s
  end

  def to_integer(fact, maps)
    assert_args(1)
    vv = the_values(0, fact, maps)
    return nil if vv.nil?
    vv[0].to_i
  end

  def to_float(fact, maps)
    assert_args(1)
    vv = the_values(0, fact, maps)
    return nil if vv.nil?
    vv[0].to_f
  end

  def to_time(fact, maps)
    assert_args(1)
    vv = the_values(0, fact, maps)
    return nil if vv.nil?
    Time.parse(vv[0].to_s)
  end
end
