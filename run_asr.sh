#!/bin/bash
# 														Hyungwon Yang
# 														hyung8758@gmail.com
# 														EMCS Labs

# This is DNN based ASR.
# The final model was trained with 117 Korean-readspeech datasets.
# For dnn training, "train_multisplice_accel2.sh" was used.


# Kaldi directory ./kaldi
kaldi=/home/kaldi
# FA data directory
data_dir=data
# result direcotry
result_dir=tmp/result
# log directory
log_dir=tmp/log
# Current directory
curdir=$PWD
# Number of jobs(just fix it to one)
mfcc_nj=1
align_nj=1
nj=1
cmd="utils/run.pl"
# Argument setting.
if [ $# -ne 1 ]; then
   echo "Input Argument:"
   echo "Model for decoding should be provided." && exit 1
fi
model_name=$1
if [ $model_name == "krs" ] || [ $model_name == "diy" ] ; then
	echo "ASR model: $model_name"
else
	echo "Model name: $model_name is not present in the model directory."
	echo "Place the model directory into ./models folder and reactivate this code." 
	echo "Provided models are as follows: " 
	echo "1. krs : Trained model based on Korean Readspeech corpus."
	echo "2. diy : Trained model based on your own corpus."
 	exit 1
fi
# model directory
model_dir=models/$model_name

if [ $model_name == "diy" ]; then
	data_count=`ls models/diy | wc -w`
	if [ $data_count -ne 4 ]; then
		echo "ERROR: diy model is selected, but it does not contain four major files: final.mat, final.mdl, HCLG.fst, and words.txt"
		exit 1
	fi
fi


# Path setting.
. path.sh $kaldi

[ ! -d data ] && mkdir data
[ -d tmp ] && rm -rf tmp
[ -f data/* ] && rm data/*

# Folders.
mkdir -p tmp/trans_data
mkdir -p tmp/log
mkdir -p tmp/mfcc

# Recording sound.
echo "Start recording..."
rec -b 16 -c 1 -r 16000 ./data/test01.wav # silence 1 0.1 1% 1 1.5 1% 

# Preprocessing
# Generate wav.scp, utt2spk, spk2utt
python3 local/asr_prep_data.py $curdir/$data_dir $curdir/tmp/trans_data >/dev/null || exit 1
utils/utt2spk_to_spk2utt.pl $curdir/tmp/trans_data/utt2spk > $curdir/tmp/trans_data/spk2utt
# wav file name. spk_id variable will be fixed.
spk_id=test01

# Extract MFCC
# MFCC default setting.
echo "Extracting the features from the input data..."
mfccdir=mfcc


# Extracting MFCC features and calculate CMVN.
steps/make_mfcc.sh --nj 1 --cmd "$cmd" $curdir/tmp/trans_data $log_dir $curdir/tmp/$mfccdir >/dev/null
utils/fix_data_dir.sh tmp/trans_data >/dev/null
steps/compute_cmvn_stats.sh $curdir/tmp/trans_data $log_dir $curdir/tmp/$mfccdir >/dev/null
utils/fix_data_dir.sh $curdir/tmp/trans_data >/dev/null

# Setting parameters
if [ $model_name == "krs" ]; then

	num_threads=1
	thread_string=
	minimize=false
	max_active=7000
	min_active=200
	beam=50.0 # 15.0
	lattice_beam=25.0 # 8.0
	acwt=0.1
	model=$model_dir/final.mdl
	cmvn_opts=
	splice_opts=
	sdata=tmp/trans_data/split$nj
	[[ -d $sdata && tmp/trans_data/feats.scp -ot $sdata ]] || split_data.sh tmp/trans_data $nj
	feats="ark,s,cs:apply-cmvn $cmvn_opts --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:$sdata/JOB/feats.scp ark:- | splice-feats $splice_opts ark:- ark:- | transform-feats $model_dir/final.mat ark:- ark:- |"

elif [ $model_name == "diy" ]; then

	num_threads=1
	thread_string=
	minimize=false
	max_active=7000
	min_active=200
	beam=30.0 # 15.0
	lattice_beam=16.0 # 8.0
	acwt=0.1
	model=$model_dir/final.mdl
	cmvn_opts=
	splice_opts=
	sdata=tmp/trans_data/split$nj
	[[ -d $sdata && tmp/trans_data/feats.scp -ot $sdata ]] || split_data.sh tmp/trans_data $nj
	feats="ark,s,cs:apply-cmvn $cmvn_opts --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:$sdata/JOB/feats.scp ark:- | splice-feats $splice_opts ark:- ark:- | transform-feats $model_dir/final.mat ark:- ark:- |"

fi

# Decoding
echo "Decoding the recorded speech."
$cmd --num-threads $num_threads JOB=1 $log_dir/decode.JOB.log \
nnet-latgen-faster$thread_string \
     --minimize=$minimize --max-active=$max_active --min-active=$min_active --beam=$beam \
     --lattice-beam=$lattice_beam --acoustic-scale=$acwt --allow-partial=true \
     --word-symbol-table=$model_dir/words.txt "$model" \
     $model_dir/HCLG.fst "$feats" "ark:|gzip -c > tmp/lat.JOB.gz"

# Echo the result.
error_msg=`cat tmp/log/decode.1.log | grep ERROR`
if [ ! -z "$error_msg" ]; then
	echo -e "Error is detected from recognition step. Please refer to the error message.\n ERROR: $error_msg"
fi

asr_result=`cat tmp/log/decode.1.log | grep $spk_id | grep -Ev 'LOG|WARNING' | head -1 | awk '{$1=""; print $0}'`
echo -e "\nASR result: $asr_result\n"



