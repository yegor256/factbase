# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase'
require_relative '../../lib/factbase/fact_as_yaml'
require_relative '../test__helper'

class TestFactAsYamlPrecision < Factbase::Test
  def test_keeps_the_sub_second_part_of_a_time
    f = Factbase.new.insert
    f.when = Time.parse('2024-03-04 05:06:07.123456 UTC')
    assert_includes(
      Factbase::FactAsYaml.new(f).to_s, '.123456',
      'a time must keep the precision the other printers keep'
    )
  end
end
