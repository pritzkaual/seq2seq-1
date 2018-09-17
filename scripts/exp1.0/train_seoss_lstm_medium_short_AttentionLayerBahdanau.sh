#!/usr/bin/env bash

DATA_DIR="/data/workspace/apritzkau/thesis/seq2seq/nmt_data/seoss/data"
MODEL_DIR="/data/workspace/apritzkau/thesis/models/trained/summarizer"

# 1 Epoch
# 226.880 (training-samples)   56.739 (test-samples)
# batch-size:		256			128
# steps:			  887		1.773

GPU=${GPU:-'1'}
TRAIN_STEPS=${TRAIN_STEPS:-20000}  # 7,9 Epochs
BATCH_SIZE=${BATCH_SIZE:-128}  # 32
LEARNING_RATE=${LEARNING_RATE:-0.0004}  # 0.0001

#SOURCE_EMBEDDING_PATH="/data/workspace/apritzkau/thesis/models/trained/embedding/word2vec_s300_a0.025_mina0.0001_minc10_w5_sg1_sample0.001_hs0_neg5_wiki.en_seoss/word2vec_e1.bin.vec"
SOURCE_EMBEDDING_PATH="/data/workspace/apritzkau/thesis/models/trained/embedding/word2vec_s300_a0.0001_mina1e-05_minc10_w5_sg1_sample0.001_hs0_neg10_wiki.en_seoss_prea0.05_premina0.0001/word2vec_e1.bin.vec"  # 1. Training
#SOURCE_EMBEDDING_PATH="/data/workspace/apritzkau/thesis/models/trained/embedding/word2vec_s300_a0.05_mina0.0001_minc10_w5_sg0_sample0.001_hs0_neg5_wiki.en/word2vec_e1.bin.vec"  # 2. Training

#TARGET_EMBEDDING_PATH=${TARGET_EMBEDDING_PATH:-0.0001}  # 0.0001

MODEL_TYPE=${MODEL_TYPE:-'lstm'}
MODEL_SIZE=${MODEL_SIZE:-'medium'}
DATASET_TYPE=${DATASET_TYPE:-'short'}
ATTENTION_LAYER=${ATTENTION_LAYER:-'Bahdanau'}

EXPERIMENT_NO=${EXPERIMENT_NO:-1.0}

export MODEL_DIR=${MODEL_DIR}/exp${EXPERIMENT_NO}.${MODEL_SIZE}.${DATASET_TYPE}.${MODEL_TYPE}.lr${LEARNING_RATE}.att${ATTENTION_LAYER}


export VOCAB_SOURCE=${DATA_DIR}/seoss.vocab.100k.tok.txt
#export VOCAB_SOURCE=${DATA_DIR}/seq2seq.vocab.100k.tok.description
export VOCAB_TARGET=${DATA_DIR}/seoss.vocab.100k.tok.txt
#export VOCAB_TARGET=${DATA_DIR}/seq2seq.vocab.100k.tok.summary

export TRAIN_SOURCES=${DATA_DIR}/train.tok.description
export TRAIN_TARGETS=${DATA_DIR}/train.tok.summary

export DEV_SOURCES=${DATA_DIR}/test.tok.description
export DEV_TARGETS=${DATA_DIR}/test.tok.summary

#export DEV_TARGETS_REF=${DATA_DIR}/newstest2013.tok.de

export BATCH_SIZE=${BATCH_SIZE}


export CUDA_DEVICE_ORDER="PCI_BUS_ID"
export CUDA_VISIBLE_DEVICES=${GPU}

# Start training

mkdir -p $MODEL_DIR

python -m bin.train \
  --config_paths="
      ./configs/seoss_${MODEL_SIZE}_${DATASET_TYPE}_${MODEL_TYPE}_AttentionLayer${ATTENTION_LAYER}.yml,
      ./configs/seoss_train_seq2seq_${DATASET_TYPE}.yml,
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
  --learning_rate ${LEARNING_RATE} \
  --output_dir ${MODEL_DIR}

