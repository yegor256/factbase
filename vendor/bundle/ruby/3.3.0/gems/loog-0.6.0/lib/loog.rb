# frozen_string_literal: true

# (The MIT License)
#
# Copyright (c) 2018-2024 Yegor Bugayenko
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
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'logger'
require 'time'

# Loog is an object-oriented wrapper around Ruby Logger:
#
#  require 'loog'
#  log = Loog::VERBOSE
#  log.info('Hello, world!')
#
# For more information read
# {README}[https://github.com/yegor256/loog/blob/master/README.md] file.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018-2024 Yegor Bugayenko
# License:: MIT
module Loog
  # Compact formatter
  COMPACT = proc do |severity, _time, _target, msg|
    prefix = ''
    case severity
    when 'ERROR', 'FATAL'
      prefix = 'E: '
    when 'DEBUG'
      prefix = 'D: '
    end
    "#{prefix}#{msg.to_s.rstrip.gsub("\n", "\n#{' ' * prefix.length}")}\n"
  end

  # Short formatter
  SHORT = proc do |_severity, _time, _target, msg|
    "#{msg.to_s.rstrip}\n"
  end

  # Full formatter
  FULL = proc do |severity, time, _target, msg|
    format(
      "%<time>s %<severity>5s %<msg>s\n",
      time: time.utc.iso8601,
      severity: severity,
      msg: msg.to_s.rstrip
    )
  end

  # No logging at all
  NULL = Logger.new($stdout)
  NULL.level = Logger::UNKNOWN
  NULL.freeze

  # Everything, including debug
  VERBOSE = Logger.new($stdout)
  VERBOSE.level = Logger::DEBUG
  VERBOSE.formatter = COMPACT
  VERBOSE.freeze

  # Info and errors, no debug info
  REGULAR = Logger.new($stdout)
  REGULAR.level = Logger::INFO
  REGULAR.formatter = COMPACT
  REGULAR.freeze

  # Errors only
  ERRORS = Logger.new($stdout)
  ERRORS.level = Logger::ERROR
  ERRORS.formatter = COMPACT
  ERRORS.freeze

  # Accumulator of everything. This class may be used
  # for testing, when it's necessary to accumulate all log
  # messages in one place and then "assert" the presence
  # of certain strings inside them.
  class Buffer < Logger
    # Ctor
    # @param [String] level The level of logging
    # @param [String] formatter The formatter
    def initialize(level: Logger::DEBUG, formatter: Loog::SHORT)
      super(
        $stdout,
        level: level,
        formatter: proc do |severity, time, target, msg|
          @lines.push(formatter.call(severity, time, target, msg))
          ''
        end
      )
      @lines = []
    end

    def to_s
      @lines.map { |s| s.dup.force_encoding('UTF-8') }.join
    end
  end
end
