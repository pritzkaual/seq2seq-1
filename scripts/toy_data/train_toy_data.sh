#!/usr/bin/env bash

OUTPUT_DIR="/data/workspace/apritzkau/thesis/seq2seq"
DATA_DIR="/data/workspace/apritzkau/thesis/dataset/train/seoss_txt_lines"

export VOCAB_SOURCE=${DATA_DIR}/vocab.sources.txt
export VOCAB_TARGET=${DATA_DIR}/vocab.targets.txt
export TRAIN_SOURCES=${DATA_DIR}/train/sources.txt
export TRAIN_TARGETS=${DATA_DIR}/train/targets.txt
export DEV_SOURCES=${DATA_DIR}/dev/sources.txt
export DEV_TARGETS=${DATA_DIR}/dev/targets.txt

export DEV_TARGETS_REF=${OUTPUT_DIR}/nmt_data/toy_reverse/dev/targets.txt
export TRAIN_STEPS=10000
export BATCH_SIZE=512

export MODEL_DIR=${OUTPUT_DIR}/nmt_tutorial

export CUDA_DEVICE_ORDER="PCI_BUS_ID"
export CUDA_VISIBLE_DEVICES="0"

# Start training

mkdir -p $MODEL_DIR

python -m bin.train \
  --config_paths="
      ./example_configs/nmt_large.yml,
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

