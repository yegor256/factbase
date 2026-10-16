# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'time'
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
        m.to_h do |k, vv|
          [k, vv.is_a?(Array) ? vv.map { |v| plain(v) } : plain(vv)]
        end
      end
    )
  end

  private

  # Render one value the way ToJSON renders it.
  # @param [Object] val The value
  # @return [Object] The value, with a Time turned into ISO 8601
  def plain(val)
    val.is_a?(Time) ? val.utc.iso8601(6) : val
  end
end
