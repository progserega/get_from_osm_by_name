#!/bin/bash
# 2 метра:
lon_sdvig=`echo 0.5/81567.167056|bc -l`
lat_sdvig=`echo 0.5/111226.255304|bc -l`

full_list="$1"
search_list="$2"

out_dir="out"

tmp="`mktemp /tmp/get_from_api.sh_XXXXXX`"
cat /dev/null > error.log
cat $search_list|while read text
do
  result="`fgrep -i \"$text\" $full_list`"
  if [ -z "${result}" ]
  then
    echo "ERROR!!! Не найдена подстанция '$text' в полном списке - выход!"
    echo "${text}" >> error.log
  else
    echo "$result" >> "${tmp}"
  fi
done

mkdir "${out_dir}"

index=1
cat $tmp|while read text
do

  lon=`echo $text|awk '{print $1}' FS='|'`
  lat=`echo $text|awk '{print $2}' FS='|'`
  name=`echo $text|awk '{print $3}' FS='|'`
  left=`echo $lon-$lon_sdvig|bc -l`
  bottom=`echo $lat-$lat_sdvig|bc -l`
  right=`echo $lon+$lon_sdvig|bc -l`
  top=`echo $lat+$lat_sdvig|bc -l`
  url="http://osm.prim.drsk.ru/api/0.6/map?bbox=$left,$bottom,$right,$top"
  echo $url
  filename1="${out_dir}/$index. `echo $name|sed 's/\//_/g'`.osm"
  filename=`echo $filename1|sed 's/"//g'`
  curl --retry 5 --retry-delay 10 -X GET "$url" -o "$filename"
  ../osm2kml/osm2kml-0.2.1/osm2kml.py "${filename}" > "${filename}.kml"
  if [ 0 != $? ]
  then
    echo "ERROR convert osm->kml for: '$name'"
    exit 1
  fi
  index=`expr $index + 1`
done
