#!/usr/bin/env bash

OUTPUT_DIR="/data/workspace/apritzkau/thesis/seq2seq"
DATA_DIR="/data/workspace/apritzkau/thesis/dataset/train/seoss_txt_lines/lower"

export VOCAB_SOURCE=${DATA_DIR}/train_issue_description.100000.freq2.voc
export VOCAB_TARGET=${DATA_DIR}/train_issue_summary.100000.freq2.voc
export TRAIN_SOURCES=${DATA_DIR}/train_issue_description.100000.BPE.txt
export TRAIN_TARGETS=${DATA_DIR}/train_issue_summary.100000.BPE.txt
export DEV_SOURCES=${DATA_DIR}/test_issue_description.100000.BPE.txt
export DEV_TARGETS=${DATA_DIR}/test_issue_summary.100000.BPE.txt

#export DEV_TARGETS_REF=${OUTPUT_DIR}/nmt_data/toy_reverse/dev/targets.txt
export TRAIN_STEPS=100000
export BATCH_SIZE=64

export MODEL_DIR=${OUTPUT_DIR}/seoss/exp2.100000

export CUDA_DEVICE_ORDER="PCI_BUS_ID"
export CUDA_VISIBLE_DEVICES="3"

# Start training

mkdir -p $MODEL_DIR

python -m bin.train \
  --config_paths="
      ./configs/seoss_large.yml,
      ./configs/train_seq2seq_seoss.yml,
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
  --keep_checkpoint_max=10\
  --save_checkpoints_steps=50\
  --batch_size $BATCH_SIZE \
  --train_steps $TRAIN_STEPS \
  --output_dir $MODEL_DIR

