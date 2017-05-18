#!/bin/bash
# 														Jaekoo Kang
# 														Hyungwon Yang
# 														EMCS Labs
#
# This script combine romanized and pronunciation texts together.
# It will be used for second word tier in Textgrid.

# Remove previous files.
if [ -f tmp/romanized/text_num ] || [ -f tmp/romanized/rom_graph_lexicon.txt ] || [ -f "tmp/romanized/list*" ]; then
	rm tmp/romanized/text_num
	rm tmp/romanized/rom_graph_lexicon.txt
	rm tmp/romanized/list*
fi

# Generate list and text_num files.
list=`ls tmp/romanized`
for l in $list; do
	cat tmp/romanized/$l | tr ' ' '\n' > tmp/romanized/list_$l
	cat tmp/romanized/$l | wc -w | awk '{print $1}'>> tmp/romanized/text_num
done

# Generate rom_graph_lexicon.txt
cat tmp/romanized/list* > tmp/romanized/rom_lexicon
paste -d ' ' tmp/romanized/rom_lexicon tmp/prono/new_lexicon > tmp/romanized/rom_graph_lexicon.txt

echo "rom_graph_lexicon.txt and text_num are generated in tmp/romanized folder."

