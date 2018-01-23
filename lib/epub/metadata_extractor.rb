# frozen_string_literal: true

require "zip"
require "epub/parser"
require "digest"

module EPUB
  ISO8601_XSD_DATETIME="%FT%T%:z"

  # Extracts metadata from an epub in the form needed for meta.yml
  class MetadataExtractor
    def initialize(epub_path, epub = Parser.parse(epub_path))
      @epub_path = epub_path
      @epub = epub
    end

    def metadata
      {
        "creation_date"  => Time.parse("2017-12-06 08:06:00-05:00").strftime(ISO8601_XSD_DATETIME),
        "creation_agent" => "umich",
        "epub_contents"  => epub_contents,
        "pagedata"       => pagedata.to_h
      }
    end

    def spine_pages
      epub.spine.items.map {|item| item.content_document.read }
    end

    def pagedata(nav=epub.nav.content_document)
      nav.contents.reject { |x| x.href.nil? }.map do |x|
        [nav.item.full_path.join(x.href).to_s, { "label" => x.text.strip }]
      end
    end

    private

    def epub_contents
      # for each... filename, checksum, mimetype, size, created
      { "rootfile"  => epub_items_info(epub.rootfiles),
        "container" => [container_info],
        "mimetype"  => [mimetype_info],
        "manifest"  => epub_items_info(epub.manifest.items),
        "spine"     => spine_items }
    end

    def epub_file_info(file = nil, path: file.full_path.to_s, mimetype: file.media_type)
      Zip::File.open(epub_path) do |epub_zip|
        entry = epub_zip.get_entry(path)
        { "filename" => path,
          "checksum" => Digest::MD5.new.update(entry.get_input_stream.read).hexdigest,
          "mimetype" => mimetype,
          "size"     => entry.size,
          "created"  => entry.time.strftime(ISO8601_XSD_DATETIME) }
      end
    end

    def container_info
      epub_file_info(
        path: "META-INF/container.xml",
        mimetype: "application/xml"
)
    end

    def mimetype_info
      epub_file_info(
        path: "mimetype",
        mimetype: "text/plain"
)
    end

    def epub_items_info(items)
      items.map {|f| epub_file_info(f) }
    end

    def spine_items
      epub.spine.items.map {|f| f.full_path.to_s }
    end

    attr_reader :epub, :epub_path
  end
end
