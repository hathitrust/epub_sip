# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "zip"
require "epub_preparer"
require "yaml"
require "pry"

RSpec.describe EPUBPreparer do
  let(:fixture) { File.dirname(__FILE__) + "/support/fixtures/ark+\=87302\=t00000001" }
  let(:input) { "#{fixture}/test.epub" }
  let(:output) { Tempfile.new("epubprep") }
  let(:subject) { described_class.new(input, output.path) }

  def yaml_safe_load(data)
    YAML.safe_load(data, [Time])
  end

  def zip_entry(filename)
    Zip::File.open(output.path) do |zipfile|
      yield zipfile.get_entry(filename)
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

  def compare_text(seq)
    zip_entry("%08d.txt" % seq) do |entry|
      expect(entry.get_input_stream.read.force_encoding("utf-8")).to eql(File.read("#{fixture}/%08d.txt" % seq))
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
      subject.run
      compare_yml_subsec("epub_contents", subsec)
    end
  end

  ["creation_date", "creation_agent", "pagedata"].each do |section|
    it "creates a meta.yml file matching the fixture's #{section} " do
      subject.run
      compare_yml_sec(section)
    end
  end

  1.upto(5) do |i|
    it "extracts text matching the fixture for seq=#{i}" do
      subject.run
      compare_text(i)
    end
  end

  it "creates a zip with the pairtree-encoded version of the given id"
  it "copies the epub"
  it "creates a checksum file matching the fixture"
  it "flattens nested navigation items"
end
