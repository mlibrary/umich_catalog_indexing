# frozen_string_literal: true

##########################################
# Helpers
##########################################

LOOKS_LIKE_LC    = /\A\s*\p{L}{1,3}\s*\d/ # 1-3 letters, digit
LOOKS_LIKE_DEWEY = /\A\s*\d{3}\s*\.\d/ # 3 digits, dot, digit

def looks_like_lc?(str)
  LOOKS_LIKE_LC.match?(str)
end

def looks_like_dewey?(str)
  LOOKS_LIKE_DEWEY.match?(str)
end

##########################################
# Standalone extractors
##########################################

# We want the 050 for LC callnumbers if we don't have another LC, but want to keep them
# separate so we always get a sort value from the 852

lc_852_extractor    = Traject::MarcExtractor.cached('852|0*|h', { alternate_script: false })
lc_050_extractor    = Traject::MarcExtractor.cached('050ab', { alternate_script: false })
dewey_852_extractor = Traject::MarcExtractor.cached('852|1*|h', { alternate_script: false })

# Still all the callnumbers into the clipboard where we can get at them

##########################################
# Puts values by tag on the clipboard for later use
##########################################

each_record do |rec, context|
  context.clipboard['callnumbers'] = {
    lc_852:    lc_852_extractor.extract(rec).flatten.compact.uniq.select { |cn| looks_like_lc?(cn) },
    lc_050:    lc_050_extractor.extract(rec).flatten.compact.uniq.select { |cn| looks_like_lc?(cn) },
    dewey_852: dewey_852_extractor.extract(rec).flatten.compact.uniq.select { |cn| looks_like_dewey?(cn) }
  }
end

# Unrestricted: whatever we have in an 852, put it here
to_field 'callnumber', extract_marc('852hij') do |rec, acc|
  acc.select! { |x| x =~ /\S/ }
end

# Callnumbers that are viable for use in the callnumber browse
# We'll take an LC or Dewey from the 852, or an LC from the 050
# if we've got nothing else

to_field 'callnumber_browse' do |rec, acc, context|
  cns     = context.clipboard['callnumbers']
  cns_852 = cns[:lc_852].concat(cns[:dewey_852])

  if cns_852.empty?
    acc.replace cns[:lc_050]
  else
    acc.replace cns_852
  end
end

# For the main sort, we'll restrict to LC/Dewey from an 852
to_field 'callnosort' do |rec, acc, context|
  lc    = context.clipboard['callnumbers'][:lc_852].first
  dewey = context.clipboard['callnumbers'][:dewey_852].first
  best  = [lc, dewey].compact.first
  acc.replace [best] if best
end

# A secondary sort, for when there's no LC/Dewey in an 852.

to_field 'callnumber_secondary_sort' do |rec, acc, context|
  any_852   = Array(context.output_hash['callnumber']).first
  need_sort = context.output_hash['callnosort'].nil?
  if need_sort and !any_852.nil?
    acc.replace [any_852]
  end
end

# The letters of any LC we can find, for visualization on the website. Not used
# in search

to_field 'callnoletters', extract_marc('852hij:050ab:090ab', :first => true) do |rec, acc|
  acc.select! { |cn| looks_like_lc?(cn) }
  unless acc.empty?
    m      = /\A\s*([A-Za-z]+)/.match(acc[0])
    acc.replace [m[1].upcase]
  end
end
