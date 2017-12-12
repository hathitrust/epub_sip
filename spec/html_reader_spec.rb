# frozen_string_literal: true

require "spec_helper"
require "html_reader"

RSpec.describe HTMLReader do
  [
    ["", ""],
    ["plain text", "plain text\n"],
    ["<html><em>fancy text</em></html>", "fancy text\n"],
    ["<html>two<br>lines</html>", "two\nlines\n"],
    ["<html><p>two</p><p>paragraphs</p></html>", "two\n\nparagraphs\n\n"],
    ["©", "©\n"],
  ].each do |html, plain|
    it "#plain_text into #{plain.inspect}" do
      expect(HTMLReader.new(html).plain_text).to eql(plain)
    end
  end
end
