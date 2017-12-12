# frozen_string_literal: true

require "zip"
require "epub/parser"
require "digest"
require "html_reader"

class EPUBPreparer
  def initialize(epub_path, output)
    @epub_path = epub_path
    @output = output

    @epub = EPUB::Parser.parse(epub_path)
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

      n = 0
      epub.spine.items.each do |item|
        n += 1
        zipfile.get_output_stream("%08d.txt" % n) do |f|
          f.write(epub_item_to_plain_text(item))
        end
      end
    end
  end

  def epub_item_to_plain_text(epub_item)
    HTMLReader.new(epub_item.content_document.read).plain_text
  end

  def meta_yml
    YAML.dump(
      "creation_date" => Time.parse("2017-12-06 08:06:00-05:00"),
      "creation_agent" => "umich",
      "epub_contents" => epub_contents,
      "pagedata" => pagedata,
    )
  end

  def pagedata
    epub.manifest.nav.content_document.navigation.items.map do |x|
      [x.item.full_path.to_s, {"label" => x.text}]
    end.to_h
  end

  def epub_contents
    # for each... filename, checksum, mimetype, size, created
    zipfile = Zip::File.open(epub_path) do |epubzip|
      { "rootfile"  => epub.rootfiles.map {|f| epub_file_info(epubzip, f) },
        "container" => [epub_file_info(epubzip, path: "META-INF/container.xml", mimetype: "application/xml")],
        "mimetype"  => [epub_file_info(epubzip, path: "mimetype", mimetype: "text/plain")],
        "manifest"  => epub.manifest.items.map {|f| epub_file_info(epubzip, f) },
        "spine"     => epub.spine.items.map {|f| f.full_path.to_s } }
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

  attr_reader :epub, :epub_path, :output
end
