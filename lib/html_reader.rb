# frozen_string_literal: true

require "open3"

# dependency-injectable runner that captures stdout and exit status
class Capture2
  def initialize(command)
    @command = command
  end

  def run(stdin_data)
    stdout_data, exit_status = Open3.capture2(command, stdin_data: stdin_data)
    if exit_status.exitstatus.zero?
      stdout_data

    else
      raise "Received exit status #{exit_status.exitstatus} on command: #{command}"
    end
  end

  private

  attr_reader :command
end

# wrapper for w3m -dump
class HTMLReader
  def initialize(html)
    @html = html
  end

  def plain_text
    Capture2.new("w3m -dump -T 'application/xhtml+xml'").run(html)
  end

  private

  attr_reader :html
end
