# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase'
require_relative '../../test__helper'

# Comments must not change the interpretation of regexp anchors.
class TestMatchesComments < Factbase::Test
  def test_keeps_whole_value_anchors_after_comments
    fb = Factbase.new
    fb.insert.text = 'abc'
    fb.insert.text = "abc\nrest"
    fb.insert.text = "rest\nabc"
    [
      '^(?# [)abc$',
      "(?x)# [\n^abc$",
      "(?x:^abc# [\n)$",
      "(?x:^(?-x:abc)# [\n)$",
      "^((?x)abc# [\n)$"
    ].each do |pattern|
      assert_equal(['abc'], fb.query('(matches text $pattern)').each(fb, pattern:).map(&:text), pattern)
    end
  end

  def test_restores_literal_hashes_after_an_extended_scope
    fb = Factbase.new
    fb.insert.text = 'abc#['
    fb.insert.text = "abc#[\nrest"
    assert_equal(['abc#['], fb.query('(matches text $pattern)').each(fb, pattern: '(?x:abc)#\[$').map(&:text))
  end

  def test_keeps_hashes_in_character_classes_and_escaped_group_text
    fb = Factbase.new
    fb.insert.text = '#abc'
    fb.insert.text = '(?#abc)'
    fb.insert.text = "#abc\nrest"
    assert_equal(['#abc'], fb.query('(matches text $pattern)').each(fb, pattern: '(?x)^[#]abc$').map(&:text))
    assert_equal(['(?#abc)'], fb.query('(matches text $pattern)').each(fb, pattern: '^\(\?\#abc\)$').map(&:text))
  end
end
