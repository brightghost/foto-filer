#! /bin/bash
# Locate likely duplicated per a few common naming conventions, particularly those filed by exiftool (e.g. -1.JPG).
# Attempts to then locate an original file, confirms suspected dupes are the same as original, and collects for disposal.

# This is *NOT* gauranteed to find any possible dupes. It only will detect duplicates which 1) are correctly filed per matching EXIF timestamps, and 2) have a shared filename with one of the expected usual dupe prefixes (currently, FILEAME-1.EXT and FILENAME 1.EXT).

# To identify any and all possible dupes would require a laborous comparison against all items in the library which is out of the scope of this utility.'

# must be executed from a directory containing dated subdirectories as created by the `-d` flag to exiftool, in order to locate originals.
# Usage:
# cleanup-duplicates.sh

# 0: print verbose debugging info
# export VERBOSE=0
# export sw_cleandupes_verbosity=1

echo "value of sw_cleandupes_verbosity: " $sw_cleandupes_verbosity
if [[ $sw_cleandupes_verbosity -eq "1" ]]; then
	echo "setting LOG_INFO"
	LOG_INFO=0
elif [[ $sw_cleandupes_verbosity -eq "2" ]]; then
	LOG_INFO=0
	LOG_VERBOSE=0
fi

if [[ $(uname) == "Darwin" ]]; then
	hash_func='md5 -r'
else
	hash_func='md5sum'
fi

[[ $iLOG_VERBOSE ]] && echo "Selected hash function: $hash_func"

export hash_func

clean_dupes () {
        # christ this seems an ugly hack but I guess it's working. find
        # -exec needs to spawn a subshell in order to call this  bash
        # function, but the form I identified that doesn't choke on spaces
        # only does so by passing the split words as separate positional
        # parameters, so we need to recombine them before operating on the
        # path.
	[[ $LOG_VERBOSE ]] && echo "executing clean_dupes with arguments $*"
	f="$(basename "$*")"
	# extension
	fe="${f##*.}"
	# 'primary' filename w/o ext.
	ff="${f%-[1-9].*}"
	fff="${ff% [1-9].*}"
	# recomposed expected priamry filename
	fp="${fff}.${fe}"
	[[ $LOG_VERBOSE ]] && echo "Searching for suspected original filename $fp"
	# use exiftool to construct a path where the original is expected to be found from EXIF tag.
	# ex: 2016/01/2016-01-07/DSCF7192.JPG
	expected_path="$(exiftool -s -S -d "%Y/%m/%Y-%m-%d" -DateTimeOriginal "$1")"
	expected_orig="./$expected_path/$fp"
	[[ $LOG_VERBOSE ]] && echo "Checking if potential original file exists at $expected_orig" 
	if [[ -f $expected_orig ]]; then
		[[ $LOG_VERBOSE ]] && echo "Located original. Testing uniqueness."
		h=$($hash_func "$1" | awk '{ print $1 }')
		hp=$($hash_func "$expected_orig" | awk '{ print $1 }')
		[[ $LOG_VERBOSE ]] && echo "Comparing hashes. a: $h b: $hp."
		if [[ $h == $hp ]]; then
			[[ $LOG_INFO ]] && echo "$1 is identical to $fp. Cleaning up."
			mkdir -p "_duplicate_images"
			mv -i "$1" "_duplicate_images/"
		else
			[[ $LOG_INFO ]] && echo "Original found for $1, but hashes differ. Leaving in place."
		fi
	else
		[[ $LOG_INFO ]] && echo "No original file found for $1. Leaving in place."
	fi
}

export -f clean_dupes

# find . -iname '*-[1-9].JPG' -not -path "./_duplicate_images/*" -exec bash -c 'clean_dupes "$0"' {} \;

find . -iname '*-[1-9].JPG' -not -path "./_duplicate_images/*" -exec bash -c 'clean_dupes "$0"' {} \;
find . -iname '* [1-9].JPG' -not -path "./_duplicate_images/*" -exec bash -c 'clean_dupes "$0"' {} \;

find . -iname '*-[1-9].RAF' -not -path "./_duplicate_images/*" -exec bash -c 'clean_dupes "$0"' {} \;
find . -iname '* [1-9].RAF' -not -path "./_duplicate_images/*" -exec bash -c 'clean_dupes "$0"' {} \;
###

[[ $LOG_INFO ]] && echo "Finished."
