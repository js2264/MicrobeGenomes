```shell
cut -f14 -d, instrsync -progress --verbose --files-from files_to_dl.txt sftpcampus:rsg_fast/abignaud/DBZ/results/ data/
/extdata/processed_files.csv | sed '1d' | sed 's,\s.*,,' > files_to_dl.txt
```
