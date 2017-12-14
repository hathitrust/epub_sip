# frozen_string_literal: true

require "html_reader"
require "epub/metadata_extractor"
require "epub/zip_file_writer"

module EPUB
  # Given an epub, generates a HathiTrust SIP
  class SIPWriter
    def initialize(pt_objid, epub_path)
      @pt_objid = pt_objid
      @epub_path = epub_path
    end

    def write_zip(output)
      metadata_extractor = MetadataExtractor.new(epub_path)
      ZipFileWriter.open(output) do |writer|
        writer.copy_file("#{pt_objid}.epub", epub_path)
        writer.write_data("meta.yml", metadata_extractor.meta_yml)

        write_ocr(metadata_extractor, writer)

        writer.write_checksums("checksum.md5")
      end
    end

    private

    def write_ocr(metadata_extractor, writer)
      n = 0
      metadata_extractor.spine_pages.each do |page|
        n += 1
        writer.write_data(format("%08d.txt", n), HTMLReader.new(page).plain_text)
      end
    end

    attr_reader :pt_objid, :epub_path
  end
end
