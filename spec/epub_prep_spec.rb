# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "zip"
require "epub_preparer"
require "yaml"
require "pry"

RSpec.describe EPUB::SIPWriter do
  let(:pt_objid) { "ark+=87302=t00000001" }
  let(:fixture) { File.dirname(__FILE__) + "/support/fixtures/#{pt_objid}" }
  let(:input) { "#{fixture}/test.epub" }
  let(:output) { Tempfile.new("epubprep") }
  let(:subject) { described_class.new(pt_objid, input) }

  def yaml_safe_load(data)
    YAML.safe_load(data, [Time])
  end

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

  def compare_yml_subsec(section, subsection)
    zip_entry("meta.yml") do |entry|
      expect(yaml_safe_load(entry.get_input_stream.read)[section][subsection]).to eql(yaml_safe_load(File.read("#{fixture}/meta.yml"))[section][subsection])
    end
  end

  def compare_yml_sec(section)
    zip_entry("meta.yml") do |entry|
      expect(yaml_safe_load(entry.get_input_stream.read)[section]).to eql(yaml_safe_load(File.read("#{fixture}/meta.yml"))[section])
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

  ["container", "mimetype", "rootfile", "manifest", "spine"].each do |subsec|
    it "creates a meta.yml file matching the fixture's epub_contents #{subsec} " do
      subject.write_zip output.path
      compare_yml_subsec("epub_contents", subsec)
    end
  end

  ["creation_date", "creation_agent", "pagedata"].each do |section|
    it "creates a meta.yml file matching the fixture's #{section} " do
      subject.write_zip output.path
      compare_yml_sec(section)
    end
  end

  1.upto(5) do |i|
    it "extracts text matching the fixture for seq=#{i}" do
      subject.write_zip output.path
      compare_text("%08d.txt" % i)
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
