#!/usr/bin/env bash

#
# This script performs the following operations:
# 1. Downloads the Flowers dataset
# 2. Fine-tunes an InceptionV3 model on the Flowers training set.
# 3. Evaluates the model on the Flowers validation set.
#
# Usage:
# cd slim
# ./slim/scripts/finetune_inceptionv3_on_flowers.sh

#set -e
#set -o pipefail
export TF_CPP_MIN_LOG_LEVEL=1

# default parameter
DATASET=${DATASET:-"seoss"}
#PRETRAINED_CHECKPOINT_DIR=${PRETRAINED_CHECKPOINT_DIR:-/tmp/checkpoints-$(id -u -n)}
BATCH_SIZE=${BATCH_SIZE:-32}
MODEL_NAME=${MODEL_NAME:-'seq2seq_xl_long'}
NUM_CLONES=${NUM_CLONES:-1}
PRETRAIN_STEPS=${PRETRAIN_STEPS:-10000}
PRETRAIN_LEARNING_RATE=${PRETRAIN_LEARNING_RATE:-0.01}
TRAIN_STEPS=${TRAIN_STEPS:-250000}
TRAIN_LEARNING_RATE=${TRAIN_LEARNING_RATE:-0.0003}
#ADD_ARGS_CONVERT=${ADD_ARGS_CONVERT:-''}
ADD_ARGS_PRETRAIN=${ADD_ARGS_PRETRAIN:-''}
#ADD_ARGS_PREEVAL=${ADD_ARGS_PREEVAL:-''}
ADD_ARGS_TRAIN=${ADD_ARGS_TRAIN:-''}
#ADD_ARGS_EVAL=${ADD_ARGS_EVAL:-''}
ARG_ALL=
ARG_TRAIN=
ARG_EVAL=

function abspath(){
    python -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' "$1"
}

function echoError()
{
	[ $# -gt 0 ] && echo -e "$1" >&2
	[ $# -gt 1 ] && [[ "$2" =~ ^[0-9]*$ ]] && return $2
}
function errorExit(){
	[ $# -gt 0 ] && echoError "Error: $1"
	[ $# -gt 1 ] && [[ "$2" =~ ^[0-9]*$ ]] && exit $2
	exit
}

function usage(){
	[ $# -gt 0 ] && echoError "$@" && echo
	filename=$(basename "$0")
	cat <<EOF
Usage:
	$filename [options] <dataset_dir> <model_dir>

	<dataset_dir>: directory containing tfrecord files or directory structure
	    containing the images.
	    If the dataset directory containing folders named train, validation and test.
	    The containing files will be used to create three datasets for
	    train, validation and test.
	    Otherwise the dataset will be splitted in train, validation and test in the ration 80/10/10.
	    Dataset structure with predefined splits:
	        <dataset_dir>/train
	                           /class1
	                                /img1.jpg
	                           /class2
	                                /img1.jpg
	                      /test
	                           /class1
	                                /img1.jpg
	                           /class2
	                                /img1.jpg
	                      /validation
	                           /class1
	                                /img1.jpg
	                           /class2
	                                /img1.jpg
	    Dataset structure without predefined splits (splits will be generated in the ration 80/10/10):
	        <dataset_dir>/class1
                                /img1.jpg
                          /class2
                                /img1.jpg
    <train_dir>: the directory to store the trained model and summaries

    Options:
        -a : use all available gpus for training default: use 2 gpus 0,1
        -e : only evaluate the model. Add option -t to evaluate only fully trained model
        -t : skip pretraining the model and continue to learn with the model in \${MODEL_PATH}
        -s <steps>: number of steps to train (pretrain will be skipped) in \${MODEL_PATH}
        -l <number>: learning rate for training
        -g <gpu_ids>: list of gpus to use e.g.: 0,1,2 default: 0,1
        -b <batch_size>: batch size
        -m <model_name>: name of the model architecture. see slim/nets/net_factory.py for available options

EOF

}

function handleOptions(){
    local IFS=$'\n'
	REST_ARGS=()
	until [ $# -eq 0 ] ; do
		while getopts  ":aethl:b:g:m:s:" opt ; do
			case $opt in
				a)	ARG_ALL=1; ;;
				e) 	ARG_EVAL=1; ;;
				t) 	ARG_TRAIN=1; ;;
				h) 	usage ; exit 0; ;;
				l) 	TRAIN_LEARNING_RATE="$OPTARG"; ;;
				g) 	ARG_GPU="$OPTARG"; ;;
				b) 	BATCH_SIZE="$OPTARG"; ;;
				m) 	MODEL_NAME="$OPTARG"; ;;
				s) 	TRAIN_STEPS="$OPTARG"; ARG_TRAIN=1; ;;
				:)  usage "missing argument: $OPTARG";;
				?)  usage "wrong option: $OPTARG";;
			esac
		done
		shift $((OPTIND-1))
		OPTIND=1
		if [ ! -z "$1" ] ; then
			REST_ARGS+=("$1");
			shift 1
		fi
	done
    [ "${#REST_ARGS[@]}" -lt 2 ] && [ ! -n "$DATASET_DIR" ] && [ ! -n "$TRAIN_DIR" ] && usage "incomplete parameters: [options] <dataset-dir> <train-dir>" && exit 1

    DATASET_DIR=${DATASET_DIR:-$(abspath "${REST_ARGS[0]}")}
    TRAIN_DIR=${TRAIN_DIR:-$(abspath "${REST_ARGS[1]}")}
    [ "${#REST_ARGS[@]}" -gt 2 ] && PRETRAINED_MODEL="${REST_ARGS[3]}"

	export CUDA_DEVICE_ORDER="PCI_BUS_ID"
    [ ! -n "$ARG_ALL" ] && export CUDA_VISIBLE_DEVICES='0,1'
    [ ! -n "$ARG_ALL" ] && NUM_CLONES=2 || NUM_CLONES=4
    if [ -n "$ARG_GPU" ] ; then
        comas=${ARG_GPU//[^,]}
        NUM_CLONES=$((${#comas} + 1))
        export CUDA_VISIBLE_DEVICES="$ARG_GPU"
    fi
}

function move_to_pyton_src_dir(){
    local relativeSrcPath="${1:-..}"
    local absdir=$(dirname "${BASH_SOURCE[0]}")
    cd "$absdir" && cd "$relativeSrcPath"
}

function download_pretrained(){
    ##
    # for a list of available models see
    # https://github.com/tensorflow/models/tree/master/slim#Pretrained
    ##
    [ -n "$PRETRAINED_CHECKPOINT_DIR" ] || return
    local model_date="2016_08_28"
    DOWNLOAD_MODEL_NAME="$MODEL_NAME"
    # https://storage.googleapis.com/download.tensorflow.org/models/nasnet-a_large_04_10_2017.tar.gz
    # http://download.tensorflow.org/models/inception_v4_2016_09_09.tar.gz
    # https://storage.googleapis.com/download.tensorflow.org/models/pnasnet-5_large_2017_12_13.tar.gz
    [ "${MODEL_NAME}" = "inception_resnet_v2" ] && model_date="2016_08_30"
    [[ "${MODEL_NAME}" =~ ^inception_v4 ]] && model_date="2017_04_14"
    [[ "${MODEL_NAME}" =~ ^resnet_v2_ ]] && model_date="2017_04_14"
    [[ "${MODEL_NAME}" =~ ^nasnet ]] && model_date="04_10_2017"
    [[ "${MODEL_NAME}" =~ ^pnasnet ]] && model_date="2017_12_13"
    [[ "${MODEL_NAME}" =~ ^nasnet_large ]] && DOWNLOAD_MODEL_NAME="nasnet-a_large"
    [[ "${MODEL_NAME}" =~ ^nasnet_mobile ]] && DOWNLOAD_MODEL_NAME="nasnet-a_mobile"
    [[ "${MODEL_NAME}" =~ ^pnasnet_large ]] && DOWNLOAD_MODEL_NAME="pnasnet-5_large"
    # Download the pre-trained checkpoint.
    if [ ! -d "$PRETRAINED_CHECKPOINT_DIR" ]; then
        mkdir ${PRETRAINED_CHECKPOINT_DIR}
    fi
    if [ ! -n "$PRETRAINED_MODEL" ] ; then
        PRETRAINED_MODEL="${PRETRAINED_CHECKPOINT_DIR}/${MODEL_NAME}"
        if [ -f "${PRETRAINED_MODEL}.ckpt" ] ; then
	        PRETRAINED_MODEL="${PRETRAINED_MODEL}.ckpt"
	        return
        fi
        if [ ! -d "$PRETRAINED_MODEL" ] ; then
            mkdir -p "$PRETRAINED_MODEL"
            local model_file="${DOWNLOAD_MODEL_NAME}_${model_date}.tar.gz"
            local url="http://download.tensorflow.org/models/${model_file}"
            cd "$PRETRAINED_MODEL"
            sp="--show-progress "
            wget -q $sp -c -N ${url} || echoError "no pretrained model $model_file found on server" 1 || return 1
            echo "extract ${model_file}"
            tar -xf "${model_file}"
            rm "${model_file}"
            cd -
        fi
        ckpt_file=$(ls "${PRETRAINED_MODEL}" | grep "\.ckpt" | head -n 1 | sed -E 's/^(.*\.ckpt.*)(.index|.data.*)$/\1/')
        [ -n "$ckpt_file" ] || errorExit "no checkpoint found in $PRETRAINED_MODEL"
        PRETRAINED_MODEL="$PRETRAINED_MODEL/$ckpt_file"
    fi
}

function convert_dataset(){
    echo "ERROR no dataset conversation is implemented here"
}

function pretrain(){

	# Fine-tune only the new layers for 10000 steps.
	python -m bin.train \
		--config_paths="
				./configs/seoss_large_long.yml,
				./configs/seoss_train_seq2seq_long.yml,
				./example_configs/text_metrics_bpe.yml" \
		--model_params "
				vocab_source: $VOCAB_SOURCE
				vocab_target: $VOCAB_TARGET" \
		--input_pipeline_train "
			class: ParallelTextInputPipeline
			params:
				source_files:
					- $TRAIN_SOURCES
				target_files:
					- $TRAIN_TARGETS" \
		--input_pipeline_dev "
			class: ParallelTextInputPipeline
			params:
				 source_files:
					- $DEV_SOURCES
				 target_files:
					- $DEV_TARGETS" \
		--gpu_allow_growth=True\
		--gpu_memory_fraction=1.0\
		--batch_size ${BATCH_SIZE} \
		--train_steps ${PRETRAIN_STEPS} \
		--output_dir ${MODEL_DIR}
}

function eval_pretrain(){

	echo "no evaluation is implemented here"

}

function train(){
	# Fine-tune all the new layers for 500 steps.
	python -m bin.train \
		--config_paths="
				./configs/seoss_large_long.yml,
				./configs/seoss_train_seq2seq_long.yml,
				./example_configs/text_metrics_bpe.yml" \
		--model_params "
				vocab_source: $VOCAB_SOURCE
				vocab_target: $VOCAB_TARGET" \
		--input_pipeline_train "
			class: ParallelTextInputPipeline
			params:
				source_files:
					- $TRAIN_SOURCES
				target_files:
					- $TRAIN_TARGETS" \
		--input_pipeline_dev "
			class: ParallelTextInputPipeline
			params:
				 source_files:
					- $DEV_SOURCES
				 target_files:
					- $DEV_TARGETS" \
		--gpu_allow_growth=True\
		--gpu_memory_fraction=1.0\
		--batch_size ${BATCH_SIZE} \
		--train_steps ${TRAIN_STEPS} \
		--output_dir ${MODEL_DIR}

}


function main(){
    handleOptions "$@"
    mkdir -p "$MODEL_DIR"
    move_to_pyton_src_dir ".."
    #[ ! -n "$ARG_TRAIN" ] && download_pretrained || true
    #convert_dataset
    if [ -n "$ARG_PRETRAIN" ]; then
        echo "pretrain"
        pretrain || true # continue if abort e.g. by user
    fi
    if [ -n "$ARG_TRAIN" ]; then
        echo "train"
        train || true # continue if abort e.g. by user
    fi
}

[[ "${BASH_SOURCE[0]}" != "${0}" ]] && return #script ${BASH_SOURCE[0]} is being sourced ...
main "$@"
