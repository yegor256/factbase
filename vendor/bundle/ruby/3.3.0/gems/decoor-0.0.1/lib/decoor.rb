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

# A function that turns decorates an object.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
def decoor(origin, attrs = {}, &)
  if block_given?
    c = Class.new do
      def initialize(origin, attrs)
        @origin = origin
        # rubocop:disable Style/HashEachMethods
        # rubocop:disable Lint/UnusedBlockArgument
        attrs.each do |k, v|
          instance_eval("@#{k} = v", __FILE__, __LINE__) # @foo = v
        end
        # rubocop:enable Style/HashEachMethods
        # rubocop:enable Lint/UnusedBlockArgument
      end

      def method_missing(*args)
        @origin.__send__(*args) do |*a|
          yield(*a) if block_given?
        end
      end

      def respond_to?(_mtd, _inc = false)
        true
      end

      def respond_to_missing?(_mtd, _inc = false)
        true
      end
    end
    c.class_eval(&)
    c.new(origin, attrs)
  else
    class_eval("def __get_origin__; @#{origin}; end", __FILE__, __LINE__) # def _get; @name; end
    class_eval do
      def method_missing(*args)
        o = __get_origin__
        o.send(*args) do |*a|
          yield(*a) if block_given?
        end
      end

      def respond_to?(_mtd, _inc = false)
        true
      end

      def respond_to_missing?(_mtd, _inc = false)
        true
      end
    end
  end
end
