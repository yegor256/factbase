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

require 'nokogiri'
require 'time'
require_relative '../factbase'

# Factbase to XML converter.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Factbase::ToXML
  # Constructor.
  def initialize(fb)
    @fb = fb
  end

  # Convert the entire factbase into XML.
  # @return [String] The factbase in XML format
  def xml
    meta = {
      factbase_version: Factbase::VERSION,
      dob: Time.now.utc.iso8601
    }
    maps = Marshal.load(@fb.export)
    Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.fb(meta) do
        maps.each do |m|
          xml.f_ do
            m.each do |k, vv|
              if vv.is_a?(Array)
                xml.send(:"#{k}_") do
                  vv.each do |v|
                    xml.send(:v, to_str(v))
                  end
                end
              else
                xml.send(:"#{k}_", to_str(vv))
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
end
