# frozen_string_literal: true

# Copyright (c) 2024-2025 Yegor Bugayenko
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

require_relative '../../factbase'

# Defn terms.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
module Factbase::Term::Defn
  def defn(_fact, _maps)
    assert_args(2)
    fn = @operands[0]
    raise "A symbol expected as first argument of 'defn'" unless fn.is_a?(Symbol)
    raise "Can't use '#{fn}' name as a term" if Factbase::Term.instance_methods(true).include?(fn)
    raise "Term '#{fn}' is already defined" if Factbase::Term.private_instance_methods(false).include?(fn)
    raise "The '#{fn}' is a bad name for a term" unless fn.match?(/^[a-z_]+$/)
    e = "class Factbase::Term\nprivate\ndef #{fn}(fact, maps)\n#{@operands[1]}\nend\nend"
    # rubocop:disable Security/Eval
    eval(e)
    # rubocop:enable Security/Eval
    true
  end

  def undef(_fact, _maps)
    assert_args(1)
    fn = @operands[0]
    raise "A symbol expected as first argument of 'undef'" unless fn.is_a?(Symbol)
    if Factbase::Term.private_instance_methods(false).include?(fn)
      Factbase::Term.class_eval("undef :#{fn}", __FILE__, __LINE__ - 1) # undef :foo
    end
    true
  end
end
