#! /bin/bash
# Build (or extend) a directory tree to organize the provided photos by EXIF date.
# Usage:
# organize-by-date.sh ./directory-containing-imports

# org into dated folder structure; no change to filename and skip dupes
# exiftool -r '-Directory<DateTimeOriginal' -d _sorted/%Y/%m/%Y-%m-%d "$1"

# org into dated folder structure; no change to filename except for dupes
# which will just be appended e.g. with '-1'. this script makes no attempt 
# to determine if these dupes are unique. see cleanup-duplicates.sh for that.
echo "Sorting image files..."
# exiftool will handle all the creation of organizational folders.
exiftool -d "_sorted/%Y/%m/%Y-%m-%d/%%f%%-c.%%e" -r '-FileName<DateTimeOriginal' "$1"

echo "Collecting .xmp files..."
mkdir -p "_xmp"
XMPDIR="_xmp"
XMPTMP=$(mktemp -d ./tmp.XXXXX) || exit 1
find "$1" -name "*.xmp" -exec mv -n '{}' "$XMPTMP" \;
# TODO: this does not work as expected when $XMPTMP is empty; may be solved by setting nullglob or failglob
for f in $XMPTMP/*; do
	echo "Checking if $f is unique..."
	if [[ ! -f "$XMPDIR/$(basename $f)" ]]; then
		echo "moving unique xmp file to $XMPDIR"
		mv -n "$f" "$XMPDIR/" 
	else
		th=$(md5sum "$XMPDIR/$(basename $f)" | awk '{ print $1 }')
		sh=$(md5sum "$f" | awk '{ print $1 }')
		if [[ $sh == $th ]]; then
			echo "$f confirmed duplicate; moving to duplicates folder."
			mkdir -p "_xmp_duplicates"
			mv "$f" "_xmp_duplicates"
		else
			echo "Ingress file $f has a duplicate candidate but hashes do not match. Moving to conflicts folder."
			mkdir -p "_import_conflicts"
			mv "$f" "_import_conflicts"
		fi
	fi
done
rmdir "$XMPTMP"
		
	
echo "Deleting empty directories..."
find "$1" -mindepth 1 type d -empty -print -delete
