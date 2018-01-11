# frozen_string_literal: true

require "spec_helper"
require "epub/metadata_extractor"
require "yaml"

require_relative "./fixtures"

RSpec.describe EPUB::MetadataExtractor do
  include_context "with epub fixtures"

  describe "#metadata" do
    let(:meta_yml) { YAML.safe_load(File.read("#{fixture}/meta.yml"), [Time]) }
    let(:subject) { described_class.new(input) }

    def compare_metadata_part(finder)
      expect(finder.call(subject.metadata)).to eql(finder.call(meta_yml))
    end

    ["container", "mimetype", "rootfile", "manifest", "spine"].each do |subsec|
      it "returns metadata matching the fixture's epub_contents #{subsec} " do
        compare_metadata_part(->(x) { x["epub_contents"][subsec] })
      end
    end

    ["creation_date", "creation_agent", "pagedata"].each do |section|
      it "returns metadata matching the fixture's #{section} " do
        compare_metadata_part(->(x) { x[section] })
      end
    end
  end

  describe "#pagedata" do
    let(:mock_epub) { double(:epub) }
    let(:nav_items) { [double(:item,
                              item: double(:foo, full_path: "/foo/bar.html"),
                              text: test_label) ] }

    before(:each) do
      allow(mock_epub).to receive_message_chain(:manifest, :nav,
        :content_document, :navigation, :items) { nav_items }
    end

    let(:test_label) { "\n SUBJECT INDEX\n " }

    it "removes whitespace from page labels" do
      expect(described_class.new("/some/path",mock_epub).pagedata)
        .to eql({ "/foo/bar.html" => { "label" => "SUBJECT INDEX" } })
    end
  end

end
