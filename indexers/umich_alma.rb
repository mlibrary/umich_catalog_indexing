require 'umich_traject'
require 'ht_traject'
#require 'ht_traject/ht_overlap.rb'
require 'json'

HathiFiles = if ENV['NODB']
               require 'ht_traject/no_db_mocks/ht_hathifiles'
               HathiTrust::NoDB::HathiFiles
             else
               require 'ht_traject/ht_hathifiles.rb'
               HathiTrust::HathiFiles
             end

# skip course reserve records 

each_record do |r, context|
  cr_pattern = /CR_RESTRICTED/
  r.each_by_tag('999') do |f|
    if f['a'] and f['a'] =~ /CR_RESTRICTED/
      id = context.output_hash['id']
      context.skip!("#{id} : Course reserve record skipped")
    end
  end
end

# 035    $a (MiU)003113534MIU01
aleph_pattern = /^\(MiU\)\d{9}MIU01$/
to_field 'aleph_id' do |record, acc, context|
  if context.clipboard[:ht][:record_source] == 'alma'
    aleph_spec = Traject::MarcExtractor.cached('035a')
    aleph_spec.extract(record).grep(aleph_pattern).each { |alephnum| 
      acc << alephnum[5,9]
    }
  end
end

#each_record do |r, context|
#  bib_nums = Array.new()
#  bib_nums << context.output_hash['aleph_id'].first if context.output_hash['aleph_id']
#  bib_nums << context.output_hash['id'].first
#  oclc_nums = context.output_hash['oclc']
#  etas_status = context.clipboard[:ht][:overlap][:count_etas] > 0
#  context.clipboard[:ht][:hf_item_list] = HathiTrust::Hathifiles.get_hf_info(oclc_nums, bib_nums, etas_status)
#end

cc_to_of = Traject::TranslationMap.new('ht/collection_code_to_original_from')
each_record do |r, context|

  locations = Array.new()
  inst_codes = Array.new()
  availability = Array.new()
  sh = Hash.new()
  has_e56 = false
  id = context.output_hash['id']

  # "OWN" field 
  r.each_by_tag(['958','OWN']) do |f|
    locations << f['a'].upcase if f['a']
    inst_codes << f['a'].upcase if f['a']
  end

  hol_list = Array.new()
  # this is ugly--needs to be refactored
  if context.clipboard[:ht][:record_source] == 'zephir'
    #cc_to_of = Traject::TranslationMap.new('ht/collection_code_to_original_from')
    # add hol for HT volumes
    items = Array.new()
    etas_status = context.clipboard[:ht][:overlap][:count_etas] > 0	# make it a boolean
    r.each_by_tag('974') do |f|
      next unless f['u']
      item = Hash.new()
      item['id'] = f['u']
      item['rights'] = f['r']
      item['description'] = f['z']
      item['collection_code'] = f['c']
      item['source'] = cc_to_of[f['c'].upcase]
      item['access'] = !!(item['rights'] =~ /^(pd|world|ic-world|cc|und-world)/)
      item['status'] = statusFromRights(item['rights'], etas_status)
      items << item
    end
    if items.any? 
      hol = Hash.new()
      hol['library'] = 'HathiTrust Digital Library' 
      hol['items'] = items
      hol_list << hol
      locations << 'MiU'
      inst_codes << 'MIU'
      inst_codes << 'MIFLIC'
    # get ht-related availability values
      availability << 'avail_ht'
      hol['items'].each do |item|
        availability << 'avail_ht_fulltext' if item[:access]
        availability << 'avail_online' if item[:access]
      end
      availability << 'avail_ht_etas' if context.clipboard[:ht][:overlap][:count_etas] > 0
    end
  else 
    r.each_by_tag('866') do |f|
      hol_mmsid = f['8']
      next if hol_mmsid == nil
      sh[hol_mmsid] = Array.new() unless sh[hol_mmsid]
      sh[hol_mmsid] << f['a']
    end
  
    items = Hash.new()
    r.each_by_tag('974') do |f|
      hol_mmsid = f['8']
      next if hol_mmsid == nil
# timothy: need to do the equivalent of this (from getHoldings):
#  next ITEM if $row{item_process_status} =~ /SD|CA|WN|MG|CS/;        # process statuses to ignore
# not sure how these will manifest in the Alma extract
      #if f['y'] and f['y'] =~ /Process Status: EO/ 
      if f['y'] and f['y'] =~ /Process Status: (EO|SD|CA|WN|MG|CS)/ 
        #logger.info "#{id} : EO item skipped"
        next
      end
      item = Hash.new()
      item['barcode'] = f['a']
      # b,c are current location
      item['library'] = f['b']		# current_library
      item['location'] = f['c']		# current_location
      item['permanent_library'] = f['d']	# permanent_library
      item['permanent_location'] = f['e']	# permanent_collection
      if item['library'] == item['permanent_library'] and item['location'] == item['permanent_location'] 
        item['temp_location'] = false
      else 
        item['temp_location'] = true
        #logger.info "#{id} : temp loc, current: #{item['library']} #{item['location']} permanent: #{item['permanent_library']} #{item['permanent_location']}"
      end
      item['callnumber'] = f['h']
      item['public_note'] = f['n']
      item['process_type'] = f['t']
      item['item_policy'] = f['p']
      item['description'] = f['z']
      item['inventory_number'] = f['i']
      item['item_id'] = f['7']
      items[hol_mmsid] = Array.new() if items[hol_mmsid] == nil 
      items[hol_mmsid] << item
      # (not sure if this is right--still investigating in the alma publish job
      availability << 'avail_circ' if f['f'] == '1'
      locations << item['library'] if item['library'] 
      locations << [item['library'], item['location']].join(' ') if item['location']
    end
  

    # get elec links for E56 fields
    r.each_by_tag('E56') do |f|
      next unless f['u']
      hol = Hash.new()
      hol['link'] = URI.escape(f['u'])
      hol['library'] = 'ELEC'
      #hol['status'] = 'Available online'
      hol['status'] = f['s'] if f['s']
      hol['link_text'] = 'Available online'
      hol['link_text'] = f['y'] if f['y']
      hol['description'] = f['3'] if f['3']
      #hol['note'] = f['z'] if f['z']
      if f['z'] 
        hol['note'] = f['z']
      elsif f['n']
        hol['note'] = f['n']
      elsif f['m']
        hol['note'] = f['m']
      end
      hol['interface_name'] = f['m'] if f['m']
      hol['collection_name'] = f['n'] if f['n']
      hol['finding_aid'] = false
      hol_list << hol
      availability << 'avail_online'
      locations << hol['library']
      if f['c'] 
        campus = f['c']
        inst_codes << 'MIU' if campus == 'UMAA'
        inst_codes << 'MIFLIC' if campus == 'UMFL'
      else 
        inst_codes << 'MIU'   
        inst_codes << 'MIFLIC'   
      end
      has_e56 = true
    end
   
    # check 856 fields:
    #   -finding aids
    #   -passwordkeeper records
    #   -other electronic resources not in alma as portfolio???
    r.each_by_tag('856') do |f|
      next unless f['u']
      link_text = f['y'] if f['y']
      if ( link_text =~ /finding aid/i ) or !has_e56 
        hol = Hash.new()
        hol['link'] = URI.escape(f['u'])
        hol['library'] = 'ELEC'
        hol['status'] = f['s'] if f['s']
        hol['link_text'] = 'Available online'
        hol['link_text'] = f['y'] if f['y']
        hol['description'] = f['3'] if f['3']
        hol['note'] = f['z'] if f['z']
        if link_text =~ /finding aid/i and hol['link'] =~ /umich/i 
          hol['finding_aid'] = true
          id = context.output_hash['id']
        else
          hol['finding_aid'] = false
        end
        availability << 'avail_online'
        hol_list << hol
  
      end
    end

    # copy-level(one for each 852)
    r.each_by_tag('852') do |f|
      hol_mmsid = f['8']
      next if hol_mmsid == nil
      next unless items[hol_mmsid]		# might also have to check for linked records
      hol = Hash.new()
      hol['hol_mmsid'] = hol_mmsid
      hol['library'] = f['b']
      hol['location'] = f['c']
      hol['callnumber'] = f['h']
      hol['public_note'] = f['z'] 
      hol['items'] = items[hol_mmsid]
      hol['summary_holdings'] = nil
      hol['summary_holdings'] = sh[hol_mmsid].join(' : ') if sh[hol_mmsid]
      hol_list << hol
      locations << f['a'].upcase if f['a']
      inst_codes << f['a'].upcase if f['a']
      locations << hol['library'] if hol['library']
      locations << [hol['library'], hol['location']].join(' ') if hol['location']
    end
  
    # add hol for HT volumes
    bib_nums = Array.new()
    bib_nums << context.output_hash['aleph_id'].first if context.output_hash['aleph_id']
    bib_nums << context.output_hash['id'].first
    oclc_nums = context.output_hash['oclc']
    etas_status = context.clipboard[:ht][:overlap][:count_etas] > 0
    #hf_item_list = HathiTrust::Hathifiles.get_hf_info(oclc_nums, bib_nums, etas_status)
    hf_item_list = HathiFiles.get_hf_info(oclc_nums, bib_nums)
    if hf_item_list.any? 
      hf_item_list.each do |r|
        r['status'] = statusFromRights(r['rights'], etas_status)
      end
      hol = Hash.new()
      hol['library'] = 'HathiTrust Digital Library' 
      hol['items'] = hf_item_list
      hol_list << hol
  
      # get ht-related availability values
      availability << 'avail_ht'
      hol['items'].each do |item|
        availability << 'avail_ht_fulltext' if item[:access]
        availability << 'avail_online' if item[:access]
      end
      availability << 'avail_ht_etas' if context.clipboard[:ht][:overlap][:count_etas] > 0
    end
  
  end

  context.clipboard[:ht][:hol_list] = hol_list
  context.clipboard[:ht][:availability] = availability.uniq
  context.clipboard[:ht][:locations] = locations.uniq
  context.clipboard[:ht][:inst_codes] = inst_codes.uniq

end

to_field 'hol' do |record, acc, context|
  acc << context.clipboard[:ht][:hol_list].to_json
end

to_field 'availability' do |record, acc, context|
  avail_map = Traject::TranslationMap.new('umich/availability_map_umich')
  acc.replace Array(context.clipboard[:ht][:availability].map { |code| avail_map[code] })
end

location_map = Traject::UMich.location_map
to_field 'location' do |record, acc, context|
  locations = Array(context.clipboard[:ht][:locations])
  #acc.replace locations.map { |code| location_map[code] }
  acc.replace locations
  acc.map! { |code| location_map[code.strip] }
  acc.flatten!
  acc.uniq!
end

#MIU, MIU-C, MIU-H, MIFLIC
inst_map = Traject::TranslationMap.new('umich/institution_map')
to_field 'institution' do |record, acc, context|
  inst_codes = Array(context.clipboard[:ht][:inst_codes])
  #acc << 'MiU' if context.clipboard[:ht][:record_source] == 'zephir'   # add MiU as an institution for zephir records
  acc.replace inst_codes
  acc.map! { |code| inst_map[code.strip] }
  acc.flatten!
  acc.uniq!
end

#######################################
# A-Z eJournal list
# ####################################
# filters:
#  - "location:ELEC"
#  - "format:Serial"
# Map first letter of the filing title to one of
# * A,B,...,Z
# "0-9" for digits
# "Other" for anything else

def ejournal?(context)
  elec = context.clipboard[:ht][:hol_list].any? { |hol| hol['library'].include? 'ELEC' }
  form = context.output_hash['format']
  elec and form.include?('Serial')
end

def first_char_map(str)
  return nil if str.nil?
  first_char = str[0]
  if first_char =~ /[A-Za-z]/
    first_char.upcase
  elsif first_char =~ /\d/
    '0-9'
  else
    'Other'
  end
end

# Get the filing versions of the primary title
to_field 'title_initial', extract_marc_filing_version('245abdefgknp', include_original: false) do |rec, acc, context|
  if ejournal?(context)
    acc.map! { |t| first_char_map(t) }
  else
    acc.replace []
  end
end



