# frozen_string_literal: true

require "open3"

class HTMLReader
  def initialize(html)
    @html = html
  end

  def plain_text
    Open3.capture2("w3m -dump -T 'application/xhtml+xml'", :stdin_data => html)[0]
  end

  private

  attr_reader :html
end
