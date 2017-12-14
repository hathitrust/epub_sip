# frozen_string_literal: true

require "spec_helper"
require "html_reader"

RSpec.describe Capture2 do
  it "can pipe input into cat" do
    expect(Capture2.new("cat").run("cheezburger")).to eql("cheezburger")
  end

  it "raises an exception on nonzero exit status" do
    expect { Capture2.new("false").run("") }.to raise_error(
      RuntimeError, "Received exit status 1 on command: false"
)
  end
end

RSpec.describe HTMLReader do
  [
    ["", ""],
    ["plain text", "plain text\n"],
    ["<html><em>fancy text</em></html>", "fancy text\n"],
    ["<html>two<br>lines</html>", "two\nlines\n"],
    ["<html><p>two</p><p>paragraphs</p></html>", "two\n\nparagraphs\n\n"],
    ["©", "©\n"]
  ].each do |html, plain|
    it "#plain_text into #{plain.inspect}" do
      expect(HTMLReader.new(html).plain_text).to eql(plain)
    end
  end
end
