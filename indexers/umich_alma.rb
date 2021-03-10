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
  #context.clipboard[:ht][:hfdata] = Hathitrust::Hathifiles.get_hf_info(oclc_nums)
  context.clipboard[:ht][:hf_item_list] = HathiTrust::Hathifiles.get_hf_info(oclc_nums, bib_nums)

end

each_record do |r, context|

  sh = Hash.new()
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
  end
  
  # add hol for HT volumes
  if context.clipboard[:ht][:hf_item_list].any? 
    hol = Hash.new()
    hol['library'] = 'HathiTrust Digital Library' 
    hol['items'] = Array(context.clipboard[:ht][:hf_item_list])
    hol_list << hol
  end

  context.clipboard[:ht][:hol_list] = hol_list

end

to_field 'hol' do |record, acc, context|
  acc << context.clipboard[:ht][:hol_list].to_json
end

#to_field 'hf_items' do |record, acc, context|
#  acc << context.clipboard[:ht][:hf_item_list].to_json
#end

  #  acc.concat aleph_spec.extract(record).grep(aleph_pattern).value[5,9]
