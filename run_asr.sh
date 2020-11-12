#!/bin/bash
# 														Hyungwon Yang
# 														hyung8758@gmail.com
# 														EMCS Labs

# 
# The final model was trained with 117 Korean-readspeech datasets.
# For dnn training, "train_multisplice_accel2.sh" was used.


# Kaldi directory ./kaldi
kaldi=/Users/yanghyungwon/kaldi
# FA data directory
data_dir=data
# result direcotry
result_dir=tmp/result
# log directory
log_dir=tmp/log
# Current directory
curdir=$PWD
# set model type
model_type=mono # mono, tri1, tri2, tri3, dnn
# Number of jobs(just fix it to one)
mfcc_nj=1
align_nj=1
nj=1
cmd="utils/run.pl"
# Argument setting.
usage="usage : $0 [ input: model name ] \n
Provided models are as follows: \n
1. krs : The model trained with Korean novel corpus. \n
2. diy : The user is able to use their own trained model. If you have a corpus and train a model, please use kaldi_tutorial script.
"

if [ $# -ne 1 ]; then
   echo -e $usage && exit 1
fi
model_name=$1
if [ $model_name == "krs" ] || [ $model_name == "diy" ] ; then
    echo "ASR model: $model_name"
else
    echo -e $usage && exit 1
fi
# model directory
model_dir=models/$model_name
if [ $model_name == "diy" ]; then
    data_count=`ls models/diy | wc -w`
    if [ $data_count -eq 0 ]; then
	echo "ERROR: diy model is selected, but it does not contain model files." && exit 1
    fi
    echo "diy mode is selected. Your model type is $model_type. This variable should be matched with the trained model type that you provided."
fi
if [ $model_type != 'mono' ] && [ $model_type != 'tri1' ] && [ $model_type != 'tri2' ] && [ $model_type != 'tri3' ] && [ $model_type != 'dnn' ]; then
    echo "ERROR: model type is unidentifiable: $model_type" && exit 1
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
steps/compute_cmvn_stats.sh $curdir/tmp/trans_data $log_dir $curdir/tmp/$mfccdir >/dev/null

# Setting parameters
if [ $model_name == "krs" ]; then

    model_type=dnn
    num_threads=1
    thread_string=
    minimize=false
    max_active=7000
    min_active=200
    beam=30.0 # 15.0
    lattice_beam=15.0 # 8.0
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
    first_max_active=2000
    max_active=7000
    min_active=200
    first_beam=10
    beam=15.0 # 15.0
    lattice_beam=8.0 # 8.0
    acwt=0.1
    model=$model_dir/final.mdl
    cmvn_opts=
    splice_opts=
    sdata=tmp/trans_data/split$nj
    [[ -d $sdata && tmp/trans_data/feats.scp -ot $sdata ]] || split_data.sh tmp/trans_data $nj
    if [ ! -f $model_dir/final.mat ]; then # mono and tri1
	echo "1st line"
	if [ $model_type != "mono" ] && [ $model_type != "tri1" ]; then
	    echo -e "Are you sure your model type is $model_type ?\nSuggest model type: mono or tri1"
	fi
	feats="ark,s,cs:apply-cmvn $cmvn_opts --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:$sdata/JOB/feats.scp ark:- | add-deltas $delta_opts ark:- ark:- |"
    elif [ -f $model_dir/final.mat ] && [ ! -f $model_dir/final.alimdl ]; then # tri2
	echo "2nd line"
	if [ $model_type == "mono" ] && [ $model_type == "tri1" ] ; then
            echo -e "Are you sure your model type is $model_type ?\nSuggest model type: tri2 or dnn"
        fi
	feats="ark,s,cs:apply-cmvn $cmvn_opts --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:$sdata/JOB/feats.scp ark:- | splice-feats $splice_opts ark:- ark:- | transform-feats $model_dir/final.mat ark:- ark:- |"
    elif [ -f $model_dir/final.alimdl ]; then # tri3
	if [ $model_type != "tri3" ]; then
            echo -e "Are you sure your model type is $model_type ?\nSuggest model type: tri3"
        fi
	feats="ark,s,cs:apply-cmvn $cmvn_opts --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:$sdata/JOB/feats.scp ark:- | splice-feats $splice_opts ark:- ark:- | transform-feats $model_dir/final.mat ark:- ark:- |"
	sifeats="ark,s,cs:apply-cmvn $cmvn_opts --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:$sdata/JOB/feats.scp ark:- | splice-feats $splice_opts ark:- ark:- | transform-feats $model_dir/final.mat ark:- ark:- |"
    fi
fi

# Decoding
echo "Decoding the recorded speech."
if [ $model_type == "dnn" ]; then
    $cmd --num-threads $num_threads JOB=1 $log_dir/decode.JOB.log \
	 nnet-latgen-faster$thread_string \
	 --minimize=$minimize --max-active=$max_active --min-active=$min_active --beam=$beam \
	 --lattice-beam=$lattice_beam --acoustic-scale=$acwt --allow-partial=true \
	 --word-symbol-table=$model_dir/words.txt "$model" \
	 $model_dir/HCLG.fst "$feats" "ark:|gzip -c > tmp/lat.JOB.gz" || exit 1;

elif [ $model_type == "mono" ] || [ $model_type == "tri1" ] || [ $model_type == "tri2" ]; then
    $cmd --num-threads $num_threads JOB=1 $log_dir/decode.JOB.log \
	 gmm-latgen-faster$thread_string --max-active=$max_active --beam=$beam --lattice-beam=$lattice_beam \
	 --acoustic-scale=$acwt --allow-partial=true --word-symbol-table=$model_dir/words.txt \
	 $model $model_dir/HCLG.fst "$feats" "ark:|gzip -c > tmp/lat.JOB.gz" || exit 1;

elif [ $model_type == "tri3" ]; then
    # do the speaker-independent decoding.
    $cmd --num-threads $num_threads JOB=1 $log_dir/decode.JOB.log \
         gmm-latgen-faster$thread_string --max-active=$first_max_active --beam=$first_beam --lattice-beam=$lattice_beam \
         --acoustic-scale=$acwt --allow-partial=true --word-symbol-table=$model_dir/words.txt \
         $model $model_dir/HCLG.fst "$feats" "ark:|gzip -c > tmp/lat.JOB.gz" || exit 1;

    # first-pass fmllr transforms
    acwt=0.083333
    silence_weight=0.01
    silphonelist=`cat $model_dir/phones/silence.csl`
    alignment_model=$model_dir/final.alimdl
    fmllr_update_type=full
    adapt_model=$model_dir/final.mdl
    final_model=$model_dir/final.mdl
    
    $cmd --max-jobs-run $num_threads JOB=1 $log_dir/fmllr_pass1.JOB.log \
	 gunzip -c tmp/lat.JOB.gz \| \
	 lattice-to-post --acoustic-scale=$acwt ark:- ark:- \| \
	 weight-silence-post $silence_weight $silphonelist $alignment_model ark:- ark:- \| \
	 gmm-post-to-gpost $alignment_model "$sifeats" ark:- ark:- \| \
	 gmm-est-fmllr-gpost --fmllr-update-type=$fmllr_update_type \
	 --spk2utt=ark:$sdata/JOB/spk2utt $adapt_model "$sifeats" ark,s,cs:- \
	 ark:tmp/pre_trans.JOB || exit 1;

    pass1feats="$sifeats transform-feats --utt2spk=ark:$sdata/JOB/utt2spk ark:tmp/pre_trans.JOB ark:- ark:- |"
    # main lattice generation phase
    $cmd --num-threads $num_threads JOB=1 $log_dir/decode.JOB.log \
    gmm-latgen-faster$thread_string --max-active=$max_active --beam=$beam --lattice-beam=$lattice_beam \
    --acoustic-scale=$acwt --determinize-lattice=false \
    --allow-partial=true --word-symbol-table=$model_dir/words.txt \
    $adapt_model $model_dir/HCLG.fst "$pass1feats" "ark:|gzip -c > tmp/lat.tmp.JOB.gz" || exit 1;

    # second pass of estimating the transform
    $cmd --max-jobs-run $num_threads JOB=1 $log_dir/fmllr_pass2.JOB.log \
	 lattice-determinize-pruned$thread_string --acoustic-scale=$acwt --beam=4.0 \
	 "ark:gunzip -c tmp/lat.tmp.JOB.gz|" ark:- \| \
	 lattice-to-post --acoustic-scale=$acwt ark:- ark:- \| \
	 weight-silence-post $silence_weight $silphonelist $adapt_model ark:- ark:- \| \
	 gmm-est-fmllr --fmllr-update-type=$fmllr_update_type \
	 --spk2utt=ark:$sdata/JOB/spk2utt $adapt_model "$pass1feats" \
	 ark,s,cs:- ark:tmp/trans_tmp.JOB '&&' \
	 compose-transforms --b-is-affine=true ark:tmp/trans_tmp.JOB ark:tmp/pre_trans.JOB \
	 ark:tmp/trans.JOB  || exit 1;

    feats="$sifeats transform-feats --utt2spk=ark:$sdata/JOB/utt2spk ark:tmp/trans.JOB ark:- ark:- |"
    # Rescore the state-level lattices. final pass of acoustic rescoring.
    $cmd --num-threads $num_threads JOB=1 $log_dir/acoustic_rescore.JOB.log \
    gmm-rescore-lattice $final_model "ark:gunzip -c tmp/lat.tmp.JOB.gz|" "$feats" ark:- \| \
    lattice-determinize-pruned$thread_string --acoustic-scale=$acwt --beam=$lattice_beam ark:- \
    "ark:|gzip -c > tmp/lat.JOB.gz" '&&' rm tmp/lat.tmp.JOB.gz || exit 1;
   
fi

# Echo the result.
error_msg=`cat tmp/log/decode.1.log | grep ERROR`
if [ ! -z "$error_msg" ]; then
	echo -e "Error is detected from recognition step. Please refer to the error message.\n ERROR: $error_msg" && exit 1
fi

asr_result=`cat tmp/log/decode.1.log | grep $spk_id | grep -Ev 'LOG|WARNING' | head -1 | awk '{$1=""; print $0}'`
echo -e "\nASR result: $asr_result\n"
