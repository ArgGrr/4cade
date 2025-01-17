#!/bin/bash

# parameters
# stdin - input containing list of game metadata, filename, display name (e.g. GAMES.CONF or some subset of it)
# stdout - binary OKVS data structure
# 1 - output filename for game count in assembler code format
# 2 - input filename of HGR titles, offsets, and sizes
# 3 - input filename of DHGR titles, offsets, and sizes

# make temp file with just the key/value pairs (strip blank lines, comments, eof marker)
records=$(mktemp)
awk '!/^$|^#|^\[/' > "$records"

# read logs of offsets & sizes for HGR and DHGR titles
# that were generated by an earlier script
hgrlog=$(< "$2")
dhgrlog=$(< "$3")

# generate source file with game count
(echo ";"
 echo "; Game count"
 echo ";"
 echo "; This file is automatically generated"
 echo ";"
 echo "!word $(wc -l < "$records")") > "$1"

# make temp assembly source file that represents the binary OKVS data structure
source=$(mktemp)
(echo '*=$6000'
 echo "!le16 $(wc -l <"$records")"     # OKVS header
 echo "!word KeyLookup"
 count=0
 while IFS="=" read -r key value; do
     count=$((count+1))
     if [ -z "$dhgrlog" ]; then
         dhgr="0"
     else
         dhgr=$(echo "$key" | cut -c3)     # 'has DHGR title screen' flag (0 or 1)
     fi
     cheat=$(echo "$key" | cut -c4)    # 'cheat category' (0..5)
     key=$(echo "$key" | cut -d"," -f2)
     if [ "$dhgr" -eq "0" ]; then
         offset=$hgrlog
         size=$hgrlog
     else
         offset=$dhgrlog
         size=$dhgrlog
     fi
     offset=$(echo "$offset" | awk -F, '/^'"$key"',/ { print $2 }')
     size=$(echo "$size" | awk -F, '/^'"$key"',/ { print $3 }')
     echo "!byte ${#key}+${#value}+10" # OKVS record length
     echo "Key${count}"
     echo "!byte ${#key}"              # OKVS key length
     echo "!text \"$key\""             # OKVS key (filename)
     echo "!byte ${#value}"            # OKVS value length
     echo "!text \"$value\""           # OKVS value (display name)
     echo "!byte 1"
     echo "!byte $((dhgr*128))+$cheat"
     echo "!be24 $offset"
     echo "!le16 $size"
 done < "$records"
 echo "KeyLookup"
 for i in $(seq $count); do
     echo "!word Key$i"
 done
) > "$source"

# assemble temp source file into binary OKVS data structure, then output that
out=$(mktemp)
acme -o "$out" "$source"
cat "$out"

# clean up
rm "$out"
rm "$source"
rm "$records"
