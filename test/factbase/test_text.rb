# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase'
require_relative '../../lib/factbase/text'

require_relative '../test__helper'

# Reads the same text out of strings of different encodings.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestText < Factbase::Test
  def test_keeps_a_utf8_string_as_it_is
    value = +'Zürich'
    assert_same(value, Factbase::Text.read(value))
  end

  def test_reads_a_binary_string_as_utf8
    value = 'Zürich'.b
    assert_equal('Zürich', Factbase::Text.read(value))
    assert_equal(Encoding::UTF_8, Factbase::Text.read(value).encoding)
  end

  def test_keeps_the_bytes_of_a_binary_string_that_is_not_text
    value = "\xFF\xFE".b
    assert_equal(value, Factbase::Text.read(value))
    assert_equal(Encoding::BINARY, Factbase::Text.read(value).encoding)
  end

  def test_transcodes_a_utf16_string
    assert_equal('Zürich', Factbase::Text.read('Zürich'.encode('UTF-16LE')))
  end

  def test_transcodes_a_latin1_string
    assert_equal('Zürich', Factbase::Text.read('Zürich'.encode('ISO-8859-1')))
  end

  def test_keeps_a_broken_utf16_string_as_it_is
    value = (+"\x00\xD8").force_encoding('UTF-16LE')
    assert_same(value, Factbase::Text.read(value))
  end

  def test_leaves_a_value_that_is_not_a_string_alone
    assert_equal(42, Factbase::Text.read(42))
  end
end
