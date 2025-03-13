# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'

# Defn terms.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
module Factbase::Defn
  def defn(_fact, _maps, _fb)
    assert_args(2)
    fn = @operands[0]
    raise "A symbol expected as first argument of 'defn'" unless fn.is_a?(Symbol)
    raise "Can't use '#{fn}' name as a term" if Factbase::Term.instance_methods(true).include?(fn)
    raise "Term '#{fn}' is already defined" if Factbase::Term.private_instance_methods(false).include?(fn)
    raise "The '#{fn}' is a bad name for a term" unless fn.match?(/^[a-z_]+$/)
    e = "class Factbase::Term\nprivate\ndef #{fn}(fact, maps, fb)\n#{@operands[1]}\nend\nend"
    # rubocop:disable Security/Eval
    eval(e)
    # rubocop:enable Security/Eval
    true
  end

  def undef(_fact, _maps, _fb)
    assert_args(1)
    fn = @operands[0]
    raise "A symbol expected as first argument of 'undef'" unless fn.is_a?(Symbol)
    if Factbase::Term.private_instance_methods(false).include?(fn)
      Factbase::Term.class_eval("undef :#{fn}", __FILE__, __LINE__ - 1) # undef :foo
    end
    true
  end
end
