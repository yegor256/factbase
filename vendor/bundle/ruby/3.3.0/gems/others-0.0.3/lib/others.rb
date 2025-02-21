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

# A function that catches all undeclared methods.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
def others(attrs = {}, &block)
  if is_a?(Class)
    class_exec(block) do |b|
      # rubocop:disable Style/ClassVars
      class_variable_set(:@@__others_block__, b)
      # rubocop:enable Style/ClassVars

      def method_missing(*args)
        raise 'Block cannot be provided' if block_given?
        b = self.class.class_variable_get(:@@__others_block__)
        instance_exec(*args, &b)
      end

      def respond_to?(_mtd, _inc = false)
        true
      end

      def respond_to_missing?(_mtd, _inc = false)
        true
      end
    end
  else
    c = Class.new do
      def initialize(attrs, &block)
        # rubocop:disable Style/HashEachMethods
        # rubocop:disable Lint/UnusedBlockArgument
        attrs.each do |k, v|
          instance_eval("@#{k} = v", __FILE__, __LINE__) # @foo = v
        end
        # rubocop:enable Style/HashEachMethods
        # rubocop:enable Lint/UnusedBlockArgument
        @block = block
      end

      def method_missing(*args)
        raise 'Block cannot be provided' if block_given?
        instance_exec(*args, &@block)
      end

      def respond_to?(_mtd, _inc = false)
        true
      end

      def respond_to_missing?(_mtd, _inc = false)
        true
      end
    end
    c.new(attrs, &block)
  end
end
