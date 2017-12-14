# frozen_string_literal: true

require "spec_helper"
require "epub/metadata_extractor"
require "yaml"

require_relative "./fixtures"

RSpec.describe EPUB::MetadataExtractor do
  include_context "with epub fixtures"

  let(:meta_yml) { YAML.safe_load(File.read("#{fixture}/meta.yml"), [Time]) }
  let(:subject) { described_class.new(input) }

  describe "#metadata" do
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
end
