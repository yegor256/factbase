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
      m.transform_values { |vv| vv.is_a?(Array) ? vv.map { |v| plain(v) } : plain(vv) }
    end.to_json
  end

  private

  # Render one value the way ToXML renders it.
  # @param [Object] val The value
  # @return [Object] The value, with a Time turned into ISO 8601
  def plain(val)
    val.is_a?(Time) ? val.utc.iso8601(6) : val
  end
end
