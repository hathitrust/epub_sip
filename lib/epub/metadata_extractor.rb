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

    def meta_yml
      YAML.dump(
        "creation_date" => Time.parse("2017-12-06 08:06:00-05:00"),
        "creation_agent" => "umich",
        "epub_contents" => epub_contents,
        "pagedata" => pagedata
      )
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
      Zip::File.open(epub_path) do |epubzip|
        { "rootfile"  => epub_items_info(epub.rootfiles, epubzip),
          "container" => [container_info(epubzip)],
          "mimetype"  => [mimetype_info(epubzip)],
          "manifest"  => epub_items_info(epub.manifest.items, epubzip),
          "spine"     => spine_items }
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

    def container_info(epubzip)
      epub_file_info(epubzip,
        path: "META-INF/container.xml",
        mimetype: "application/xml")
    end

    def mimetype_info(epubzip)
      epub_file_info(epubzip,
        path: "mimetype",
        mimetype: "text/plain")
    end

    def epub_items_info(items, epubzip)
      items.map {|f| epub_file_info(epubzip, f) }
    end

    def spine_items
      epub.spine.items.map {|f| f.full_path.to_s }
    end

    attr_reader :epub, :epub_path
  end
end
