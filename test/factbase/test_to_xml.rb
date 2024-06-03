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
    assert(!xml.xpath('/fb[@dob]').empty?)
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

  def test_sorts_keys
    fb = Factbase.new
    f = fb.insert
    f.x = 20
    f.t = 40
    f.a = 10
    f.c = 1
    xml = Factbase::ToXML.new(fb).xml
    assert(xml.gsub(/\s*/, '').include?('<f><a>10</a><c>1</c><t>40</t><x>20</x></f>'), xml)
  end
end
