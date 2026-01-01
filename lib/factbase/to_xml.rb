# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'time'
require_relative '../factbase'
require_relative '../factbase/flatten'

# Factbase to XML converter.
#
# This class helps converting an entire Factbase to YAML format, for example:
#
#  require 'factbase/to_xml'
#  fb = Factbase.new
#  puts Factbase::ToXML.new(fb).xml
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::ToXML
  # Constructor.
  def initialize(fb, sorter = '_id')
    @fb = fb
    @sorter = sorter
  end

  # Convert the entire factbase into XML.
  # @return [String] The factbase in XML format
  def xml
    bytes = @fb.export
    meta = {
      version: Factbase::VERSION,
      size: bytes.size
    }
    Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.fb(meta) do
        Factbase::Flatten.new(Marshal.load(bytes), @sorter).it.each do |m|
          xml.f_ do
            m.sort.to_h.each do |k, vv|
              if vv.is_a?(Array)
                xml.send(:"#{k}_") do
                  vv.each do |v|
                    xml.send(:v, to_str(v), t: type_of(v))
                  end
                end
              else
                xml.send(:"#{k}_", to_str(vv), t: type_of(vv))
              end
            end
          end
        end
      end
    end.to_xml
  end

  private

  def to_str(val)
    if val.is_a?(Time)
      val.utc.iso8601
    else
      val.to_s
    end
  end

  def type_of(val)
    val.class.to_s[0]
  end
end
