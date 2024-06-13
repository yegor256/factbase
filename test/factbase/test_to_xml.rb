# frozen_string_literal: true

# Copyright (c) 2024 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'minitest/autorun'
require 'loog'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/to_xml'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestToXML < Minitest::Test
  def test_simple_rendering
    fb = Factbase.new
    fb.insert.t = Time.now
    to = Factbase::ToXML.new(fb)
    xml = Nokogiri::XML.parse(to.xml)
    assert(!xml.xpath('/fb/f[t]').empty?)
    assert(
      xml.xpath('/fb/f/t/text()').text.match?(
        /^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$/
      )
    )
  end

  def test_complex_rendering
    fb = Factbase.new
    fb.insert.t = "\uffff < > & ' \""
    to = Factbase::ToXML.new(fb)
    xml = Nokogiri::XML.parse(to.xml)
    assert(!xml.xpath('/fb/f[t]').empty?)
  end

  def test_meta_data_presence
    fb = Factbase.new
    fb.insert.x = 42
    to = Factbase::ToXML.new(fb)
    xml = Nokogiri::XML.parse(to.xml)
    assert(!xml.xpath('/fb[@version]').empty?)
    assert(!xml.xpath('/fb[@size]').empty?)
  end

  def test_to_xml_with_short_names
    fb = Factbase.new
    f = fb.insert
    f.type = 1
    f.f = 2
    f.class = 3
    to = Factbase::ToXML.new(fb)
    xml = Nokogiri::XML.parse(to.xml)
    assert(!xml.xpath('/fb/f/type').empty?)
    assert(!xml.xpath('/fb/f/f').empty?)
    assert(!xml.xpath('/fb/f/class').empty?)
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
    ].each { |x| assert(!xml.xpath(x).empty?, out) }
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
      assert(!xml.xpath("/fb/f/#{e}[count(preceding-sibling::*) = #{i}]").empty?, e)
    end
  end
end
