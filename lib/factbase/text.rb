# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../factbase'

# Reads a string as UTF-8 text.
#
# The setter of a fact, the operand of a query and the key of an index all
# read their strings through this, so the same text stored and queried in
# different encodings is one value. A string whose bytes can't be read as
# text, like +"\xFF\xFE"+ read as bytes, keeps its own encoding and bytes,
# because there is no text to read.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
module Factbase::Text
  # Convert a string to UTF-8, reading the bytes of a binary one as UTF-8.
  # @param [Object] value The value of a fact, of a query operand, or of an index key
  # @return [Object] The string in UTF-8, or the same value if it can't be read as text
  def self.read(value)
    return value unless value.is_a?(String)
    return value if value.encoding == Encoding::UTF_8
    if value.encoding == Encoding::BINARY
      utf = value.dup.force_encoding(Encoding::UTF_8)
      return utf.valid_encoding? ? utf : value
    end
    value.encode(Encoding::UTF_8)
  rescue EncodingError
    value
  end
end
