# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'time'
require_relative '../factbase'
require_relative '../factbase/flatten'

# Factbase to XML converter.
#
# This class helps converting an entire Factbase to XML format, for example:
#
#  require 'factbase/to_xml'
#  fb = Factbase.new
#  puts Factbase::ToXML.new(fb).xml
#
# A value holding a character that XML 1.0 cannot represent is printed
# in Base64 and marked with t="B", since printing it verbatim would make
# the document not well-formed.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::ToXML
  BAD = /[^\u0009\u000A\u000D\u0020-\uD7FF\uE000-\uFFFD\u{10000}-\u{10FFFF}]/

  # Constructor.
  def initialize(fb, sorter = '_id')
    @fb = fb
    @sorter = sorter
  end

  # Convert the entire factbase into XML.
  # @return [String] The factbase in XML format
  def xml
    meta = { version: Factbase::VERSION, size: @fb.size }
    Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.fb(meta) do
        Factbase::Flatten.new(@fb.each.to_a, @sorter).it.each do |m|
          xml.f_ do
            m.sort.to_h.each do |k, vv|
              if vv.is_a?(Array)
                xml.__send__(:"#{k}_") do
                  vv.each do |v|
                    put(xml, :v, v)
                  end
                end
              else
                put(xml, :"#{k}_", vv)
              end
            end
          end
        end
      end
    end.to_xml
  end

  private

  # Put one value into the document, in Base64 if XML cannot hold it verbatim.
  # @param [Nokogiri::XML::Builder] xml The builder
  # @param [Symbol] name The name of the element
  # @param [Object] val The value
  def put(xml, name, val)
    if val.is_a?(String) && val.match?(BAD)
      xml.__send__(name, [val].pack('m0'), t: 'B')
    else
      xml.__send__(name, to_str(val), t: type_of(val))
    end
  end

  def to_str(val)
    if val.is_a?(Time)
      val.utc.iso8601(6)
    else
      val.to_s
    end
  end

  def type_of(val)
    val.class.to_s[0]
  end
end
