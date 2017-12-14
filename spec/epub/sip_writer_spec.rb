# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "zip"
require "epub/sip_writer"
require_relative "./fixtures"

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
