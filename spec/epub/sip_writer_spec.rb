# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "zip"
require "epub_sip"
require "yaml"
require "pry"

RSpec.shared_context "with epub fixtures" do
  let(:input) { "#{fixture}/test.epub" }
  let(:fixture) { File.dirname(__FILE__) + "/../support/fixtures/#{pt_objid}" }
  let(:pt_objid) { "ark+=87302=t00000001" }
end

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

RSpec.describe EPUB::SIPWriter do
  include_context "with epub fixtures"

  let(:output) { Tempfile.new("epubprep") }
  let(:subject) { described_class.new(pt_objid, input) }

  def zip_entry(filename)
    Zip::File.open(output.path) do |zipfile|
      yield zipfile.get_entry(filename)
    end
  end

  def zip_find(filename)
    Zip::File.open(output.path) do |zipfile|
      zipfile.find_entry(filename)
    end
  end

  def compare_text(filename)
    zip_entry(filename) do |entry|
      expect(entry.get_input_stream.read.force_encoding("utf-8")).to eql(File.read("#{fixture}/#{filename}"))
    end
  end

  before(:each) do
    output.close
  end

  after(:each) do
    output.close
    output.unlink
  end

  1.upto(5) do |i|
    it "extracts text matching the fixture for seq=#{i}" do
      subject.write_zip output.path
      compare_text(format("%08d.txt", i))
    end
  end

  it "copies the epub" do
    subject.write_zip output.path
    expect(zip_find("#{pt_objid}.epub")).not_to be(nil)
  end

  it "creates a checksum file matching the fixture" do
    subject.write_zip output.path
    zip_entry("checksum.md5") do |entry|
      expect(entry.get_input_stream.read.count("\n")).to eql(File.read("#{fixture}/checksum.md5").count("\n"))
    end
  end

  # can't test this without a new fixture
  it "flattens nested navigation items"
end
