# frozen_string_literal: true

require "zip"
require "digest"

module EPUB
  # Generates a zip file with checksum.md5
  class ZipFileWriter
    def self.open(output)
      Zip::File.open(output, Zip::File::CREATE) do |zipfile|
        writer = ZipFileWriter.new(zipfile)
        yield writer
      end
    end

    def initialize(zipfile)
      @zipfile = zipfile
      @checksums = {}
    end

    def copy_file(outfile, infile)
      checksums[outfile] = Digest::MD5.hexdigest(File.read(infile))
      zipfile.add(outfile, infile)
    end

    def write_data(outfile, data)
      checksums[outfile] = Digest::MD5.hexdigest(data)
      zipfile.get_output_stream(outfile) {|f| f.write(data) }
    end

    def write_checksums(outfile)
      zipfile.get_output_stream(outfile) do |f|
        checksums.to_a.sort.each do |filename, checksum|
          f.write("#{checksum}  #{filename}\n")
        end
      end
    end

    private

    attr_reader :zipfile, :checksums
  end
end
