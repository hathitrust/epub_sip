# frozen_string_literal: true

require "zip"
require "epub/parser"
require "digest"

module EPUB
  # Extracts metadata from an epub in the form needed for meta.yml
  class MetadataExtractor
    def initialize(epub_path)
      @epub_path = epub_path

      @epub = Parser.parse(epub_path)
    end

    def metadata
      {
        "creation_date"  => Time.parse("2017-12-06 08:06:00-05:00"),
        "creation_agent" => "umich",
        "epub_contents"  => epub_contents,
        "pagedata"       => pagedata
      }
    end

    def spine_pages
      epub.spine.items.map {|item| item.content_document.read }
    end

    private

    def pagedata
      epub.manifest.nav.content_document.navigation.items.map do |x|
        [x.item.full_path.to_s, { "label" => x.text }]
      end.to_h
    end

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
          "created"  => entry.time }
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
