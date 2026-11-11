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
    xml = Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml)
    refute_empty(xml.xpath('/fb/f[t]'))
    assert_match(
      /^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{9}Z$/,
      xml.xpath('/fb/f/t/text()').text
    )
  end

  def test_keeps_offset_of_stored_time
    time = Time.new(2024, 1, 1, 12, 0, 0, '+03:00')
    xml = Nokogiri::XML.parse(Factbase::ToXML.new(Factbase.new([{ '_id' => [1], 't' => [time] }])).xml)
    assert_equal('2024-01-01T09:00:00.000000000Z', xml.xpath('/fb/f/t/text()').text, xml.to_s)
    assert_equal(10_800, time.utc_offset, 'printing moved the stored time to UTC')
  end

  def test_control_character_rendering
    fb = Factbase.new
    fb.insert.t = "a#{1.chr}b"
    node = Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml, &:strict).xpath('/fb/f/t').first
    assert_equal('B', node['t'])
    assert_equal("a#{1.chr}b", node.text.unpack1('m0'))
  end

  def test_broken_utf8_rendering
    fb = Factbase.new
    bad = +"bad\xFF"
    bad.force_encoding('UTF-8')
    fb.insert.t = bad
    node = Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml, &:strict).xpath('/fb/f/t').first
    assert_equal('B', node['t'])
    assert_equal(bad.b, node.text.unpack1('m0').b)
  end

  def test_binary_and_latin1_rendering
    fb = Factbase.new
    f = fb.insert
    f.a = "data\xC3\xA9".b
    f.b = "\xFF\xFE".b
    f.c = (+"data\xE9").force_encoding(Encoding::ISO_8859_1)
    xml = Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml, &:strict)
    assert_equal("data\u00e9", xml.xpath('/fb/f/a').first.text)
    assert_equal('B', xml.xpath('/fb/f/b').first['t'])
    assert_equal("\xFF\xFE".b, xml.xpath('/fb/f/b').first.text.unpack1('m0').b)
    assert_equal("data\u00e9", xml.xpath('/fb/f/c').first.text)
  end

  def test_complex_rendering
    fb = Factbase.new
    fb.insert.t = "\uffff < > & ' \""
    refute_empty(Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml).xpath('/fb/f[t]'))
  end

  def test_meta_data_presence
    fb = Factbase.new
    fb.insert.x = 42
    xml = Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml)
    refute_empty(xml.xpath('/fb[@version]'))
    refute_empty(xml.xpath('/fb[@size]'))
    assert_equal('1', xml.xpath('/fb/@size').text)
  end

  def test_size_counts_the_facts
    fb = Factbase.new
    3.times { |i| fb.insert.x = i }
    assert_equal('3', Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml).xpath('/fb/@size').text)
  end

  def test_to_xml_with_short_names
    fb = Factbase.new
    f = fb.insert
    f.type = 1
    f.f = 2
    xml = Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml)
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

  def test_marks_booleans_differently_from_floats_and_times
    fb = Factbase.new
    f = fb.insert
    f.truth = true
    f.lie = false
    f.float = 2.5
    f.time = Time.now
    xml = Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml)
    %w[truth lie].each { |name| refute_empty(xml.xpath("/fb/f/#{name}[@t=\"L\"]")) }
    refute_empty(xml.xpath('/fb/f/float[@t="F"]'))
    refute_empty(xml.xpath('/fb/f/time[@t="T"]'))
  end

  def test_sorts_keys
    fb = Factbase.new
    f = fb.insert
    f.x = 20
    f.t = 40
    f.a = 10
    f.c = 1
    xml = Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml)
    %w[a c t x].each_with_index do |e, i|
      refute_empty(xml.xpath("/fb/f/#{e}[count(preceding-sibling::*) = #{i}]"), e)
    end
  end

  def test_custom_sorter
    fb = Factbase.new
    f = fb.insert
    f.name = 'b'
    f.w = 2
    f = fb.insert
    f.name = 'a'
    f.w = 1
    out = Factbase::ToXML.new(fb, 'w').xml
    assert_equal(%w[a b], Nokogiri::XML.parse(out).xpath('/fb/f/name').map(&:text), out)
  end

  def test_keeps_nanoseconds_of_time
    fb = Factbase.new
    fb.insert.when = Time.utc(2026, 9, 30) + Rational(123_456_789, 1_000_000_000)
    assert_includes(Factbase::ToXML.new(fb).xml, '2026-09-30T00:00:00.123456789Z')
  end

  def test_empty_factbase
    xml = Nokogiri::XML.parse(Factbase::ToXML.new(Factbase.new).xml)
    refute_empty(xml.xpath('/fb'))
    assert_operator(Integer(xml.xpath('/fb/@size').first.value, 10), :>=, 0)
  end

  def test_prints_facts_modified_inside_txn
    seed = Random.new_seed
    fb = Factbase.new
    fb.insert._id = 1
    value = Random.new(seed).rand(1..1000)
    text = nil
    fb.txn do |fbt|
      fbt.query('(eq _id 1)').each { |f| f.bar = value }
      text = Factbase::ToXML.new(fbt).xml
    end
    assert_includes(
      text, "<bar t=\"I\">#{value}</bar>",
      "printed facts miss the bar of #{value} written inside txn, seed #{seed}"
    )
  end
end
