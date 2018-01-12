# frozen_string_literal: true

require "spec_helper"
require "epub/metadata_extractor"
require "yaml"

require_relative "./fixtures"

RSpec.describe EPUB::MetadataExtractor do
  describe "#metadata" do
    context "with an epub with a flat nav" do
      include_context "with simple epub fixtures"
      subject { described_class.new(simple_epub) }

      let(:meta_yml) { YAML.safe_load(File.read("#{fixture}/meta.yml"), [Time]) }

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

    context "with a epub with nested hierarchy" do
      let(:fixture) { File.dirname(__FILE__) + "/../support/fixtures" }
      let(:nested_epub) { "#{fixture}/test_nested.epub" }
      let(:meta_yml) { YAML.safe_load(File.read("#{fixture}/test_nested_meta.yml"), [Time]) }

      subject { described_class.new(nested_epub) }

      it "returns metadata matching the fixture's pagedata" do
        expect(subject.metadata["pagedata"]).to eql(meta_yml["pagedata"])
      end
    end
  end

  describe "#pagedata" do
    let(:mock_epub) { double(:epub) }
    let(:item) do
      double(:item,
        item: double(:foo, full_path: "/foo/bar.html"),
        text: test_label)
    end

    let(:nav) { double(:nav, contents: [item]) }

    let(:test_label) { "\n SUBJECT INDEX\n " }

    it "removes whitespace from page labels" do
      expect(described_class.new("/some/path", mock_epub).pagedata(nav))
        .to eql([["/foo/bar.html", { "label" => "SUBJECT INDEX" }]])
    end
  end
end
