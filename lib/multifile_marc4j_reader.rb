# encoding: utf-8
require 'traject/marc4j_reader'
require 'marc'
require 'stringio'

module Traject
  class MultiFileMarc4JReader < Traject::Marc4JReader

    # @param [Traject::Reader]
    def initialize(input_stream, settings)
      @settings = settings
      globs = get_and_validate_globs(settings)
      super
      @inputs = streams_from_globs(globs)
    end


    # We're getting some items from alma with encoding problems that manifest when
    # trying to generate JSON. Because it's not already too slow to index, we'll
    # do a vacuous #to_json on the record and capture the error for logging

    def can_be_jsonified(r)
      r.to_hash.to_json
      :ok
    rescue JSON::GeneratorError, Encoding::UndefinedConversionError => e
      e
    end

    alias_method :old_each, :each

    def each
      return to_enum(:each) unless block_given?
      @inputs.each do |stream|
        filename = stream.first
        @input_stream = stream.last
        logger.info("Processing #{filename}")

        @internal_reader = create_marc_reader!
        already_retried = false
        i = 0
        self.old_each do |r|
          i += 1
          jsonifiable = can_be_jsonified(r)
          if jsonifiable == :ok
            already_retried = false
            yield r
          else
            id = r["001"].value
            if already_retried
              logger.error "Skipping un-json-ifyable record #{id} (record #[i} in  #{filename}): #{jsonifiable}"
            else
              logger.warn "Scrubbing record #{id} (record #{i} in file #{filename}) and retrying due to #{jsonifiable.inspect}"
              str = r.to_xml.to_s.scrub
              r = MARC::XMLReader.new(StringIO.new(str)).first
              redo
            end
          end
        end
      end
    end

    private

    def get_and_validate_globs(settings)
      globstr = settings['source_glob']
      globs = globstr.split(/\s*,\s*/)
      raise "#{self} requires setting 'source_glob' to be set" if globs.empty?
      globs
    end

    def open_stream(filename)
      if @settings["marc_source.encoding"] == "xml"
        File.open(filename, 'r:utf-8')
      else
        File.open(filename, 'r')
      end
    end

    def streams_from_globs(globs)
      streammap = globs.each_with_object({}) { |g, h| h[g] = Dir.glob(g).map { |f| [f, open_stream(f)] } }
      streammap.each_pair do |g, s|
        if s.empty?
          logger.warn "Glob '#{g}' matched no files"
        else
          logger.info "Glob '#{g}' matched #{s.size} files"
        end
      end
      streams = streammap.values.flatten(1)
      if streams.empty?
        msg = "#{self.class} aborting. No files matching any of '#{globs.join(",")}' found"
        logger.fatal(msg)
        exit 1
      end
      streams
    end

  end
end
   
