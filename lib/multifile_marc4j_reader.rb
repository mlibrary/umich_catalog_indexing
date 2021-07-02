require 'traject/marc4j_reader'
require 'marc'
require 'stringio'

module Traject
  class MultiFileMarc4JReader < Traject::Marc4JReader

    # @param [Traject::Reader]
    def initialize(input_stream, settings)
      globs = get_and_validate_globs(settings)
      super
      @inputs = streams_from_globs(globs)
    end

    alias_method :old_each, :each

    # We're getting some items from alma with encoding problems that manifest when
    # trying to generate JSON. Because it's not already too slow to index, we'll
    # do a vacuous #to_json on the record and capture the error for logging

    def can_be_jsonified(r)
      r.to_hash.to_json
      :ok
    rescue JSON::GeneratorError => e
      e
    end

    def each
      return to_enum(:each) unless block_given?
      @inputs.each do |stream|
        filename = stream.first
        @input_stream = stream.last
        logger.info("Processing #{filename}")

        @internal_reader = create_marc_reader!
        already_retried = false
        self.old_each do |r|
          jsonifiable = can_be_jsonified(r)
          if jsonifiable == :ok
            already_retried = false
            yield r
          else
            id = r["001"]
            filenaem
            if already_retried
              logger.error "Skipping un-json-ifyable record #{id} in file #{filename}: #{jsonifiable}"
            else
              new_xml = MARC::XMLReader.new(StringIO.new(r.to_xml.scrub)).first
              logger.warn "Scrubbing record #{id} in file #{filename} and retrying"
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

    def streams_from_globs(globs)
      streammap = globs.each_with_object({}) { |g, h| h[g] = Dir.glob(g).map { |f| [f, File.open(f, 'r')] } }
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
   
