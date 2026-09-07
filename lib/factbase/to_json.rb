# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'json'
require 'time'
require_relative '../factbase'
require_relative '../factbase/flatten'

# Factbase to JSON converter.
#
# This class helps converting an entire Factbase to JSON format, for example:
#
#  require 'factbase/to_json'
#  fb = Factbase.new
#  puts Factbase::ToJSON.new(fb).json
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::ToJSON
  # Constructor.
  def initialize(fb, sorter = '_id')
    @fb = fb
    @sorter = sorter
  end

  # Convert the entire factbase into JSON.
  # @return [String] The factbase in JSON format
  def json
    Factbase::Flatten.new(@fb.each.to_a, @sorter).it.map do |m|
      m.to_h do |k, vv|
        [k, vv.is_a?(Array) ? vv.map { |v| plain(m, k, v) } : plain(m, k, vv)]
      end
    end.to_json
  end

  private

  # Render one value the way ToXML renders it.
  # @param [Hash] map The fact the value belongs to
  # @param [String] key The name of the property
  # @param [Object] val The value
  # @return [Object] The value, with a Time turned into ISO 8601
  def plain(map, key, val)
    if val.is_a?(String) && !val.valid_encoding?
      raise(
        ArgumentError,
        "The value #{val.inspect} of the '#{key}' property of the fact " \
        "##{map['_id']} is not valid UTF-8 and JSON cannot hold it"
      )
    end
    val.is_a?(Time) ? val.utc.iso8601(6) : val
  end
end
