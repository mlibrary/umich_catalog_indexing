require 'umich_traject'
require 'ht_traject'
require 'ht_traject/ht_hathifiles.rb'
require 'json'

# 035    $a (MiU)003113534MIU01
aleph_pattern = /^\(MiU\)\d{9}MIU01$/
to_field 'aleph_id' do |record, acc|
  aleph_spec = Traject::MarcExtractor.cached('035a')
  aleph_spec.extract(record).grep(aleph_pattern).each { |alephnum| 
    acc << alephnum[5,9]
  }
end

each_record do |r, context|
  bib_nums = Array.new()
  bib_nums << context.output_hash['aleph_id']  
  bib_nums << context.output_hash['id']  
  oclc_nums = Array(context.output_hash['oclc'])
  context.clipboard[:ht][:hf_item_list] = HathiTrust::Hathifiles.get_hf_info(oclc_nums, bib_nums)

end

each_record do |r, context|

  locations = Array.new()
  availability = Array.new()
  sh = Hash.new()

  # "OWN" field 
  r.each_by_tag(['958','OWN']) do |f|
    locations << f['a'].upcase if f['a']
  end

  r.each_by_tag('866') do |f|
    hol_mmsid = f['8']
    next if hol_mmsid == nil
    sh[hol_mmsid] = Hash.new()
    sh[hol_mmsid]['summary_holdings'] = f['a']
  end

  items = Hash.new()
  r.each_by_tag('974') do |f|
    hol_mmsid = f['8']
    next if hol_mmsid == nil
    item = Hash.new()
    item['barcode'] = f['a']
    item['library'] = f['b']
    item['location'] = f['c']
    item['public_note'] = f['n']
    item['process_type'] = f['t']
    item['description'] = f['z']
    item['item_id'] = f['7']
    items[hol_mmsid] = Array.new() if items[hol_mmsid] == nil 
    items[hol_mmsid] << item
    # (not sure if this is right--still investigating in the alma publish job
    availability << 'avail_circ' if f['f'] == '1'
    locations << item['library'] if item['library'] 
    locations << [item['library'], item['location']].join(' ') if item['location']
  end

  hol_list = Array.new()
  r.each_by_tag('852') do |f|
    hol_mmsid = f['8']
    next if hol_mmsid == nil
    hol = Hash.new()
    hol['hol_mmsid'] = hol_mmsid
    hol['library'] = f['b']
    hol['location'] = f['c']
    hol['callnumber'] = f['h']
    hol['public_note'] = f['z'] 
    hol['items'] = items[hol_mmsid]
    hol['summary_holdings'] = sh[hol_mmsid]
    hol_list << hol
    locations << f['a'] if f['a']
    locations << hol['library'] if hol['library']
    locations << [hol['library'], hol['location']].join(' ') if hol['location']
  end

  # add hol for HT volumes
  if context.clipboard[:ht][:hf_item_list].any? 
    hol = Hash.new()
    hol['library'] = 'HathiTrust Digital Library' 
    hol['items'] = Array(context.clipboard[:ht][:hf_item_list])
    hol_list << hol

    # get ht-related availability values
    # still need to get etas availability, by reading the umich overlap file
    availability << 'avail_ht'
    hol['items'].each do |item|
      availability << 'avail_ht_fulltext' if item[:access]
    end
  end

  context.clipboard[:ht][:hol_list] = hol_list
  context.clipboard[:ht][:availability] = availability.uniq
  context.clipboard[:ht][:locations] = locations.uniq

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
#  acc.map! { |code| location_map[code.strip] }
#  acc.flatten!
#  acc.uniq!
