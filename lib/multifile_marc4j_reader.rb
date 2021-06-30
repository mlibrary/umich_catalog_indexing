require 'traject/marc4j_reader'

module Traject
  class MultiFileMarc4JReader < Traject::Marc4JReader

    # @param [Traject::Reader]
    def initialize(input_stream, settings)
      globs = get_and_validate_globs(settings)
      super
      @inputs = streams_from_globs(globs)
    end

    alias_method :old_each, :each

    def each
      return to_enum(:each) unless block_given?
      @inputs.each do |stream|
        logger.info("Processing #{stream.first}")
        @input_stream = stream.last
        @internal_reader = create_marc_reader!
        self.old_each do |r|
          yield r
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
      streammap = globs.each_with_object({}) { |g, h| h[g] = Dir.glob(g).map{|f| [f, File.open(f, 'r')]}}
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
   
