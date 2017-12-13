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

    Zip::File.open(output, Zip::File::CREATE) do |zipfile|
      sums = {}
      zipfile.add("#{pt_objid}.epub", epub_path)
      sums["#{pt_objid}.epub"] = Digest::MD5.hexdigest(File.read(epub_path))

      sums["meta.yml"] = Digest::MD5.hexdigest(preparer.meta_yml)
      zipfile.get_output_stream("meta.yml") do |f|
        f.write(preparer.meta_yml)
      end

      n = 0
      preparer.spine_pages.each do |page|
        n += 1
        sums["%08d.txt" % n] = Digest::MD5.hexdigest(HTMLReader.new(page).plain_text)
        zipfile.get_output_stream("%08d.txt" % n) do |f|
          f.write(HTMLReader.new(page).plain_text)
        end
      end

      zipfile.get_output_stream("checksum.md5") do |f|
        sums.to_a.sort.each do |filename, hash|
          f.write("#{hash}  #{filename}\n")
        end
      end
    end
  end

  private

  attr_reader :pt_objid, :epub_path
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
