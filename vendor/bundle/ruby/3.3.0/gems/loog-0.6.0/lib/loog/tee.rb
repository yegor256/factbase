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

require_relative '../loog'

# A combiner of a few logs together:
#
#  require 'loog'
#  tee = Loog::Tee.new(Loog::VERBOSE, file_logger)
#  log.info('Hello, world!')
#
# This way you can log to console and to the file at the same time.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018-2024 Yegor Bugayenko
# License:: MIT
class Loog::Tee
  # Makes an instance.
  def initialize(*logs)
    @logs = logs
  end

  def debug(msg)
    @logs.each { |g| g.debug(msg) }
  end

  def debug?
    @logs.any? { |g| g.debug?(msg) }
  end

  def info(msg)
    @logs.each { |g| g.info(msg) }
  end

  def info?
    @logs.any? { |g| g.info?(msg) }
  end

  def warn(msg)
    @logs.each { |g| g.warn(msg) }
  end

  def warn?
    @logs.any? { |g| g.warn?(msg) }
  end

  def error(msg)
    @logs.each { |g| g.error(msg) }
  end
end
