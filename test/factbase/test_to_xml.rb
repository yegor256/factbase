# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require 'loog'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/to_xml'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestToXML < Factbase::Test
  def test_simple_rendering
    fb = Factbase.new
    fb.insert.t = Time.now
    to = Factbase::ToXML.new(fb)
    xml = Nokogiri::XML.parse(to.xml)
    refute_empty(xml.xpath('/fb/f[t]'))
    assert_match(
      /^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$/, xml.xpath('/fb/f/t/text()').text
    )
  end

  def test_complex_rendering
    fb = Factbase.new
    fb.insert.t = "\uffff < > & ' \""
    to = Factbase::ToXML.new(fb)
    xml = Nokogiri::XML.parse(to.xml)
    refute_empty(xml.xpath('/fb/f[t]'))
  end

  def test_meta_data_presence
    fb = Factbase.new
    fb.insert.x = 42
    to = Factbase::ToXML.new(fb)
    xml = Nokogiri::XML.parse(to.xml)
    refute_empty(xml.xpath('/fb[@version]'))
    refute_empty(xml.xpath('/fb[@size]'))
  end

  def test_to_xml_with_short_names
    fb = Factbase.new
    f = fb.insert
    f.type = 1
    f.f = 2
    to = Factbase::ToXML.new(fb)
    xml = Nokogiri::XML.parse(to.xml)
    refute_empty(xml.xpath('/fb/f/type'))
    refute_empty(xml.xpath('/fb/f/f'))
  end

  def test_show_types_as_attributes
    fb = Factbase.new
    f = fb.insert
    f.a = 42
    f.b = 3.14
    f.c = 'Hello'
    f.d = Time.now
    f.e = 'e'
    f.e = 4
    out = Factbase::ToXML.new(fb).xml
    xml = Nokogiri::XML.parse(out)
    [
      '/fb/f/a[@t="I"]',
      '/fb/f/b[@t="F"]',
      '/fb/f/c[@t="S"]',
      '/fb/f/d[@t="T"]',
      '/fb/f/e/v[@t="S"]',
      '/fb/f/e/v[@t="I"]'
    ].each { |x| refute_empty(xml.xpath(x), out) }
  end

  def test_sorts_keys
    fb = Factbase.new
    f = fb.insert
    f.x = 20
    f.t = 40
    f.a = 10
    f.c = 1
    to = Factbase::ToXML.new(fb)
    xml = Nokogiri::XML.parse(to.xml)
    %w[a c t x].each_with_index do |e, i|
      refute_empty(xml.xpath("/fb/f/#{e}[count(preceding-sibling::*) = #{i}]"), e)
    end
  end
end
