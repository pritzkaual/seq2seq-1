#!/usr/bin/env bash

OUTPUT_DIR="/data/workspace/apritzkau/thesis/seq2seq/nmt_data/wmt16_de_en"
DATA_DIR="${OUTPUT_DIR}/data"

export MODEL_DIR=${OUTPUT_DIR}/training/exp1.medium


export VOCAB_SOURCE=${DATA_DIR}/vocab.bpe.32000
export VOCAB_TARGET=${DATA_DIR}/vocab.bpe.32000
export TRAIN_SOURCES=${DATA_DIR}/train.tok.clean.bpe.32000.en
export TRAIN_TARGETS=${DATA_DIR}/train.tok.clean.bpe.32000.de
export DEV_SOURCES=${DATA_DIR}/newstest2013.tok.bpe.32000.en
export DEV_TARGETS=${DATA_DIR}/newstest2013.tok.bpe.32000.de

export DEV_TARGETS_REF=${DATA_DIR}/newstest2013.tok.de
export TRAIN_STEPS=1000000

export BATCH_SIZE=128


export CUDA_DEVICE_ORDER="PCI_BUS_ID"
export CUDA_VISIBLE_DEVICES="0"

# Start training

mkdir -p $MODEL_DIR

python -m bin.train \
  --config_paths="
      ./example_configs/nmt_medium.yml,
      ./example_configs/train_seq2seq.yml,
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
  --batch_size $BATCH_SIZE \
  --train_steps $TRAIN_STEPS \
  --output_dir $MODEL_DIR

