# University of Michigan Solr Indexing for the catalog

## Most common usages for the scripts in /bin

```
export SOLR_URL="http://localhost:8025/solr/biblio" # this is the default

bin/index_today # logfile automatically created in logs/daily/
bin/index_date 20190901 <optional_logfile>
bin/catchup_since 20190901 # run all the dailies including that date

bin/index_file /path/to/file.seq.gz <optional_logfile>

bin/update_tmaps # re-derive HLB file and HT collection codes

```

### index_today

* Will take solr url from $SOLR_URL
* Automatically figures out the date
* Just runs index_date on the right date
* Puts a logfile in logs/daily/daily/daily_yyyymmdd.txt


### catchup_since YYYYMMDD

* Figures out the start date and today's date
* ...and calls index_date repeatedly

### index_date YYYYMMDD <opt logfile>

* Just delete/index that date

### index_file /path/to/file.seq[.gz]

* Index that file, but doesn't do the deletes

## Where are all the important variables / locations / etc. set?

`bin/utils.sh`. This is called by just about everything else.

## What scripts are available?

Where appropriate, all scripts will respect the SOLR_URL enivronment variable, which
defaults to "http://localhost:8025/solr/biblio" (the dev instance). The `index_*` commands
also take an explicit logfile path as the final argument

The useful scripts are as follows, all in the `bin` directory

* `index_today` -- figure out today's date and find/index today's files, putting the log in `logs/daily`
* `index_date` -- same as above, but pass the date as YYYYMMDD 
* `index_file` -- Index only (no deletes) the given alephsequential file (.seq or .seq.gz)
* `catchup_since` -- index all the daily updates starting at the date given as YYYYMMDD
* `update_tmaps` -- update the translation maps. Right now, only updates HLB (as `lib/translation_maps/hlb.json.gz`)
* `commit` -- just send a commit

The following are not yet functional in a useful way
* `delete_all`
* `test_marc_file_for_hlb`
* `fullindex`

These are low-level files called by the above
* `tindex`
* `utils.sh`

## Notes

Lots of dead code in here, vestiges of when the umich/ht indexing was unified
