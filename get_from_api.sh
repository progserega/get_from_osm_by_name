#!/bin/bash
# 2 метра:
lon_sdvig_2_metres=`echo 2/81567.167056|bc -l`
lat_sdvig_2_metres=`echo 2/111226.255304|bc -l`

full_list="$1"
search_list="$2"

out_dir="out"

tmp="`mktemp /tmp/get_from_api.sh_XXXXXX`"

cat $search_list|while read text
do
  fgrep "$text" $full_list >> "$tmp"
done 

mkdir "${out_dir}"

index=1
cat $tmp|while read text
do

  lon=`echo $text|awk '{print $1}' FS='|'`
  lat=`echo $text|awk '{print $2}' FS='|'`
  name=`echo $text|awk '{print $3}' FS='|'`
  left=`echo $lon-$lon_sdvig_2_metres|bc -l`
  bottom=`echo $lat-$lat_sdvig_2_metres|bc -l`
  right=`echo $lon+$lon_sdvig_2_metres|bc -l`
  top=`echo $lat+$lat_sdvig_2_metres|bc -l`
  url="http://osm.prim.drsk.ru/api/0.6/map?bbox=$left,$bottom,$right,$top"
  echo $url
  filename1="${out_dir}/$index. `echo $name|sed 's/\//_/g'`.osm"
  filename=`echo $filename1|sed 's/"//g'`
  curl --retry 5 --retry-delay 10 -X GET "$url" -o "$filename"
  ../osm2kml/osm2kml-0.2.1/osm2kml.py "${filename}" > "${filename}.kml"
  index=`expr $index + 1`
done
