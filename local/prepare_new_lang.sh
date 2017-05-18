#!/bin/bash
#                             EMCS Labs
#                             Hyungwon Yang
#                             hyung8758@gmail.com


if [ $# -ne 4 ]; then
   echo "Three arguments should be assigned." 
   echo "1. dictionary directory."
   echo "2. language directory."
   echo "3. data directory."
   echo "4. oov_word" && exit 1
fi

# dictionary directory.
dict_dir=$1
# language directory.
lang_dir=$2
# Data directory.
data_dir=$3
# oov word.
oov_word=$4

### dict directory ###
# lexcionp.
perl -ape 's/(\S+\s+)(.+)/${1}1.0\t$2/;' < $dict_dir/lexicon.txt > $dict_dir/lexiconp.txt

# silence.
echo -e "<SIL>\n<UNK>" >  $dict_dir/silence_phones.txt
echo "silence.txt file was generated."

# nonsilence.
awk '{$1=""; print $0}' $dict_dir/lexicon.txt | tr -s ' ' '\n' | sort -u | sed '/^$/d' > $dict_dir/nonsilence_phones.txt
echo "nonsilence.txt file was generated."

# optional_silence.
echo '<SIL>' >  $dict_dir/optional_silence.txt
echo "optional_silence.txt file was generated."

# extra_questions.
cat $dict_dir/silence_phones.txt| awk '{printf("%s ", $1);} END{printf "\n";}' > $dict_dir/extra_questions.txt || exit 1;
cat $dict_dir/nonsilence_phones.txt | perl -e 'while(<>){ foreach $p (split(" ", $_)) {  $p =~ m:^([^\d]+)(\d*)$: || die "Bad phone $_"; $q{$2} .= "$p "; } } foreach $l (values %q) {print "$l\n";}' >> $dict_dir/extra_questions.txt || exit 1;
echo "extra_questions.txt file was generated."

# Insert <UNK> in the lexicon.txt and lexiconp.txt.
sed -i '1 i\<UNK> <UNK>' $dict_dir/lexicon.txt
sed -i '1 i\<UNK> 1.0 <UNK>' $dict_dir/lexiconp.txt

### lang directory ###
utils/prepare_lang.sh $dict_dir $oov_word main/data/local/lang $lang_dir 1>/dev/null


