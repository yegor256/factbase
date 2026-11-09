# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
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
#  fb.insert.foo = 42
#  f = fb.query('(eq foo 42)').each.to_a.first
#  puts Factbase::FactAsYaml.new(f).to_s
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
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
        key(k),
        ': ',
        if vv.size == 1
          v_to_s(vv.first)
        else
          [
            '[',
            vv.map { |v| v_to_s(v) }.join(', '),
            ']'
          ]
        end
      ].zip.join
    end.join("\n")
  end

  private

  # A property name YAML would read as a boolean or null, like +yes+ or +null+, gets quoted.
  def key(name)
    YAML.safe_load(name).is_a?(String) ? name : "'#{name}'"
  end

  def v_to_s(val)
    s = val
    s = unicode(s).ellipsized.inspect if s.is_a?(String)
    s = s.getutc.iso8601(9) if s.is_a?(Time)
    s
  end

  # Convert a string to UTF-8, since YAML can't print one in another encoding;
  # keep its bytes as binary when they can't be transcoded.
  # @param [String] val The value
  # @return [String] The value in UTF-8, or as binary
  def unicode(val)
    return val if val.encoding == Encoding::UTF_8
    val.encode(Encoding::UTF_8)
  rescue EncodingError
    val.b
  end
end
