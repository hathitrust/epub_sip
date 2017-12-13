# frozen_string_literal: true

require "zip"
require "epub/parser"
require "digest"
require "html_reader"

class EPUB::SIPWriter
  def initialize(pt_objid, epub_path)
    @pt_objid = pt_objid
    @epub_path = epub_path
  end

  def write_zip(output)
    preparer = EPUB::Preparer.new(epub_path)
    EPUB::ZipFileWriter.open(output) do |writer|
      writer.copy_file("#{pt_objid}.epub", epub_path)
      writer.write_data("meta.yml", preparer.meta_yml)

      n = 0
      preparer.spine_pages.each do |page|
        n += 1
        writer.write_data("%08d.txt" % n, HTMLReader.new(page).plain_text)
      end

      writer.write_checksums("checksum.md5")
    end
  end

  private

  attr_reader :pt_objid, :epub_path
end

class EPUB::ZipFileWriter
  def self.open(output)
    Zip::File.open(output, Zip::File::CREATE) do |zipfile|
      writer = EPUB::ZipFileWriter.new(zipfile)
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
    zipfile.get_output_stream(outfile) { |f| f.write(data) }
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

class EPUB::Preparer
  def initialize(epub_path)
    @epub_path = epub_path

    @epub = EPUB::Parser.parse(epub_path)
  end

  def meta_yml
    YAML.dump(
      "creation_date" => Time.parse("2017-12-06 08:06:00-05:00"),
      "creation_agent" => "umich",
      "epub_contents" => epub_contents,
      "pagedata" => pagedata,
    )
  end

  def spine_pages
    epub.spine.items.map {|item| item.content_document.read}
  end

  private

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

  attr_reader :epub, :epub_path
end
