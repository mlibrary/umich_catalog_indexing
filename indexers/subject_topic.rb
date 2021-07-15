$:.unshift "#{File.dirname(__FILE__)}/../lib"

require_relative '../lib/umich_traject'
extend Traject::Macros::UMich::SubjectMacros

################################
######## SUBJECT / TOPIC  ######
################################

# We get the full topic (LCSH), but currently want to ignore
# entries that are FAST entries (those having second-indicator == 7)


skip_FAST = ->(rec, field) do
  field.indicator2 == '7' and field['2'] =~ /fast/
end

to_field "topic", extract_marc_unless(%w(
  600a  600abcdefghjklmnopqrstuvxyz
  610a  610abcdefghklmnoprstuvxyz
  611a  611acdefghjklnpqstuvxyz
  630a  630adefghklmnoprstvxyz
  648a  648avxyz
  650a  650abcdevxyz
  651a  651aevxyz
  653a  653abevyz
  654a  654abevyz
  655a  655abvxyz
  656a  656akvxyz
  657a  657avxyz
  658a  658ab
  662a  662abcdefgh
  690a   690abcdevxyz

  ), skip_FAST, :trim_punctuation => true)

to_field 'lc_subject_display', lcsh_subjects
to_field 'non_lc_subject_display', non_lcsh_subjects
