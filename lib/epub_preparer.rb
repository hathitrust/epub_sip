# frozen_string_literal: true

require "zip"
require "epub/parser"
require "digest"

class EPUBPreparer
  def initialize(input, output)
    @input = input
    @output = output
  end

  def run
    write_zip
  end

  private

  def write_zip
    Zip::File.open(output, Zip::File::CREATE) do |zipfile|
      zipfile.get_output_stream("meta.yml") do |f|
        f.write(meta_yml)
      end
    end
  end

  def meta_yml
    YAML.dump(
      "creation_date" => Time.parse("2017-12-06 08:06:00-05:00"),
      "creation_agent" => "umich",
      "epub_contents" => epub_contents
    )
  end

  def epub_contents
    # for each... filename, checksum, mimetype, size, created
    book = EPUB::Parser.parse(input)
    zipfile = Zip::File.open(input) do |epubzip|
      { "rootfile"  => book.rootfiles.map {|f| epub_file_info(epubzip, f) },
        "container" => [epub_file_info(epubzip, path: "META-INF/container.xml", mimetype: "application/xml")],
        "mimetype"  => [epub_file_info(epubzip, path: "mimetype", mimetype: "text/plain")],
        "manifest"  => book.manifest.items.map {|f| epub_file_info(epubzip, f) },
        "spine"     => book.spine.items.map {|f| f.full_path.to_s } }
    end
  end

  def epub_file_info(zip, file = nil, path: file.full_path.to_s, mimetype: file.media_type)
    entry = zip.get_entry(path)
    { "filename" => path,
      "checksum" => Digest::MD5.new.update(entry.get_input_stream.read).hexdigest,
      "mimetype" => mimetype,
      "size"     => entry.size,
      "created"  => entry.time }
  end

  attr_reader :input, :output
end
