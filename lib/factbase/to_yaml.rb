# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'yaml'
require_relative '../factbase'
require_relative '../factbase/flatten'

# Factbase to YAML converter.
#
# This class helps converting an entire Factbase to YAML format, for example:
#
#  require 'factbase/to_yaml'
#  fb = Factbase.new
#  puts Factbase::ToYAML.new(fb).yaml
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::ToYAML
  # Constructor.
  def initialize(fb, sorter = '_id')
    @fb = fb
    @sorter = sorter
  end

  # Convert the entire factbase into YAML.
  # @return [String] The factbase in YAML format
  def yaml
    YAML.dump(
      Factbase::Flatten.new(@fb.each.to_a, @sorter).it.map do |m|
        m.transform_values { |vv| vv.is_a?(Array) ? vv.map { |v| unicode(v) } : unicode(vv) }
      end
    )
  end

  private

  # Convert a string to UTF-8 if its encoding is not ASCII-compatible,
  # since YAML can't print such a string (UTF-16, UTF-32), and turn a string
  # with invalid bytes into a binary copy, which YAML prints as binary.
  # @param [Object] val The value
  # @return [Object] The value, with such a string in UTF-8 or binary
  def unicode(val)
    return val unless val.is_a?(String)
    return val.b unless val.valid_encoding?
    return val if val.encoding.ascii_compatible?
    val.encode(Encoding::UTF_8)
  end
end
