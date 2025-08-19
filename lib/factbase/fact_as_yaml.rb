# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'ellipsized'
require 'yaml'
require_relative '../factbase'

# Single fact to YAML converter.
#
# This class helps converting a single fact to YAML format, for example:
#
#  require 'factbase/fact_as_yaml'
#  fb = Factbase.new
#  f = fb.query('(eq foo 42)').to_a.first
#  puts Factbase::FactAsYaml.new(f).to_s
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::FactAsYaml
  # Constructor.
  def initialize(fact)
    @fact = fact
  end

  # Convert the fact to YAML.
  # @return [String] The fact in YAML format
  def to_s
    props = @fact.all_properties
    hash = {}
    props.each do |p|
      v = @fact[p]
      hash[p] = v.is_a?(Array) ? v : [v]
    end
    hash.sort.to_h.map do |k, vv|
      [
        k,
        ': [',
        vv.map do |v|
          v = v.ellipsized if v.is_a?(String)
          v = v.utc.iso8601 if v.is_a?(Time)
          v
        end.map(&:inspect).join(', '),
        ']'
      ].join
    end.join("\n")
  end
end
