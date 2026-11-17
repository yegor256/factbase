# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/term'
require_relative '../../test__helper'

# Incompatible encodings must not hide another comparable value.
class TestCompareEncoding < Factbase::Test
  def test_tries_other_values_on_either_side_in_either_order
    %w[contains starts_with ends_with].each do |op|
      ['needle', 'needle'.encode(Encoding::UTF_16LE)].permutation.each do |values|
        fb = Factbase.new
        fb.import(Marshal.dump([{ 'text' => values }]))
        assert_equal(1, fb.query("(#{op} text 'needle')").each.to_a.size)
        assert_equal(1, fb.query("(#{op} 'needle' text)").each.to_a.size)
      end
    end
  end

  def test_returns_false_when_a_comparable_pair_does_not_match
    %w[contains starts_with ends_with].each do |op|
      fb = Factbase.new
      fb.import(Marshal.dump([{ 'text' => ['needle'.encode(Encoding::UTF_16LE), 'hay'] }]))
      assert_empty(fb.query("(#{op} text 'needle')").each.to_a)
      assert_empty(fb.query("(#{op} 'needle' text)").each.to_a)
    end
  end

  def test_reports_context_when_no_encoding_pair_can_be_compared
    %w[contains starts_with ends_with].each do |op|
      fb = Factbase.new
      fb.import(Marshal.dump([{ 'text' => ['needle'.encode(Encoding::UTF_16LE)] }]))
      error =
        assert_raises(Factbase::Term::Wrapped) do
          fb.query("(#{op} text 'needle')").each.to_a
        end
      assert_includes(error.message, 'Cannot compare')
      assert_includes(error.message, 'incompatible character encodings')
    end
  end
end
