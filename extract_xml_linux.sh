#/!bin/bash

xml_file=$1

# grep by desired keyword
cat $xml_file | grep -E "(config type=\"(adc.*\">$|dac.*waveform\">$)|sampFreq|ddc0NcoFreq|ddc1NcoFreq|decimation|centerFreq|bandwidth|afterPulseDelay|alpha|scale|numPoints|numInt|adcMode|bypass|rg)" > tmp

# awk to good format
cat tmp \
	| awk '{ gsub("config type", "configType"); print $0 }' \
	| awk '{ gsub("</.*$", ""); print $0 }' \
	| awk '{ gsub("(^\s*<|\">$)", "", $1); print $1 }' \
	| awk '{ gsub("(=\"|>)", "\t"); print $0 }' \
	> tmp2

# delete duplicate of demication (the first occurence)
# comment out for now
#cat tmp2 | awk '/decimation.*/ && !f{f=1; next} 1' > tmp3
cat tmp2 > tmp3

echo -e "PARAMETER\tVALUE" > ${xml_file%.*}.tsv
cat tmp3 >> ${xml_file%.*}.tsv

# print the processed xml, feel free to comment out

cat ${xml_file%.*}.tsv |  awk '{ gsub("\t", ","); print $0 }' >${xml_file%.*}.csv

cat ${xml_file%.*}.tsv
echo
cat ${xml_file%.*}.csv

# delete imtermediate file
rm -f tmp tmp2 tmp3

