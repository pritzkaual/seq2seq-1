#! /usr/bin/env bash

# Copyright 2017 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"



DATASET_DIR=${DATASET_DIR:-/data/workspace/apritzkau/thesis/dataset/train/seoss_txt_lines/lower}

OUTPUT_DIR=${OUTPUT_DIR:-/data/workspace/apritzkau/thesis/seq2seq/nmt_data/seoss}
echo "Writing to ${OUTPUT_DIR}. To change this, set the OUTPUT_DIR environment variable."

OUTPUT_DIR_TMPDATA="${OUTPUT_DIR}/__data"
OUTPUT_DIR_DATA="${OUTPUT_DIR}/data"

mkdir -p ${OUTPUT_DIR_TMPDATA}
mkdir -p ${OUTPUT_DIR_DATA}


# Extract everything
echo "Move dataset to temporary data path..."
mkdir -p "${OUTPUT_DIR_TMPDATA}"
cp ${DATASET_DIR}/*_issue_description.txt ${OUTPUT_DIR_TMPDATA}/
cp ${DATASET_DIR}/*_issue_summary.txt ${OUTPUT_DIR_TMPDATA}/

# Concatenate Training data
cat "${OUTPUT_DIR_TMPDATA}/train_issue_description.txt"\
  > "${OUTPUT_DIR_DATA}/train.description"
wc -l "${OUTPUT_DIR_DATA}/train.description"

cat "${OUTPUT_DIR_TMPDATA}/train_issue_summary.txt"\
  > "${OUTPUT_DIR_DATA}/train.summary"
wc -l "${OUTPUT_DIR_DATA}/train.summary"

# Concatenate Test data
cat "${OUTPUT_DIR_TMPDATA}/test_issue_description.txt"\
  > "${OUTPUT_DIR_DATA}/test.description"
wc -l "${OUTPUT_DIR_DATA}/test.description"

cat "${OUTPUT_DIR_TMPDATA}/test_issue_summary.txt"\
  > "${OUTPUT_DIR_DATA}/test.summary"
wc -l "${OUTPUT_DIR_DATA}/test.summary"


# Clone Moses
if [ ! -d "${OUTPUT_DIR}/mosesdecoder" ]; then
  echo "Cloning moses for data processing"
  git clone https://github.com/moses-smt/mosesdecoder.git "${OUTPUT_DIR}/mosesdecoder"
fi


# Tokenize data
for f in ${OUTPUT_DIR_DATA}/*.summary; do
	echo "Tokenizing $f..."
	${OUTPUT_DIR}/mosesdecoder/scripts/tokenizer/tokenizer.perl -q -l en -threads 8 < $f > ${f%.*}.tok.summary
done

for f in ${OUTPUT_DIR_DATA}/*.description; do
	echo "Tokenizing $f..."
	${OUTPUT_DIR}/mosesdecoder/scripts/tokenizer/tokenizer.perl -q -l en -threads 8 < $f > ${f%.*}.tok.description
done

# Clean all corpora
for f in ${OUTPUT_DIR_DATA}/*.description; do
  fbase=${f%.*}
  echo "Cleaning ${fbase}..."
  ${OUTPUT_DIR}/mosesdecoder/scripts/training/clean-corpus-n.perl $fbase summary description "${fbase}.clean" 1 80
done

# Create character vocabulary (on tokenized data)
if [ ! -f ${OUTPUT_DIR_DATA}/vocab.tok.char.description ]; then
	python3 ${BASE_DIR}/bin/tools/generate_vocab.py --delimiter "" \
		< ${OUTPUT_DIR_DATA}/train.tok.clean.description \
		> ${OUTPUT_DIR_DATA}/vocab.tok.char.description
fi
if [ ! -f ${OUTPUT_DIR_DATA}/vocab.tok.char.summary ]; then
	python3 ${BASE_DIR}/bin/tools/generate_vocab.py --delimiter "" \
		< ${OUTPUT_DIR_DATA}/train.tok.clean.summary \
	  > ${OUTPUT_DIR_DATA}/vocab.tok.char.summary
fi

# Create character vocabulary (on non-tokenized data)
if [ ! -f ${OUTPUT_DIR_DATA}/vocab.char.description ]; then
	python3 ${BASE_DIR}/bin/tools/generate_vocab.py --delimiter "" \
		< ${OUTPUT_DIR_DATA}/train.clean.description \
		> ${OUTPUT_DIR_DATA}/vocab.char.description
fi
if [ ! -f ${OUTPUT_DIR_DATA}/vocab.char.summary ]; then
	python3 ${BASE_DIR}/bin/tools/generate_vocab.py --delimiter "" \
		< ${OUTPUT_DIR_DATA}/train.clean.summary \
		> ${OUTPUT_DIR_DATA}/vocab.char.summary
fi

# Create vocabulary for DESCRIPTION data
if [ ! -f ${OUTPUT_DIR_DATA}/vocab.50k.description ]; then
	python3 ${BASE_DIR}/bin/tools/generate_vocab.py \
		 --max_vocab_size 50000 \
		< ${OUTPUT_DIR_DATA}/train.tok.clean.description \
		> ${OUTPUT_DIR_DATA}/vocab.50k.description
fi
# Create vocabulary for SUMMARY data
if [ ! -f ${OUTPUT_DIR_DATA}/vocab.50k.summary ]; then
	python3 ${BASE_DIR}/bin/tools/generate_vocab.py \
		--max_vocab_size 50000 \
		< ${OUTPUT_DIR_DATA}/train.tok.clean.summary \
		> ${OUTPUT_DIR_DATA}/vocab.50k.summary
fi

# Generate Subword Units (BPE)
# Clone Subword NMT
if [ ! -d "${OUTPUT_DIR}/subword-nmt" ]; then
  git clone https://github.com/rsennrich/subword-nmt.git "${OUTPUT_DIR}/subword-nmt"
fi

# Learn Shared BPE
for merge_ops in 32000; do
  echo "Learning BPE with merge_ops=${merge_ops}. This may take a while..."
  cat "${OUTPUT_DIR_DATA}/train.tok.clean.summary" "${OUTPUT_DIR_DATA}/train.tok.clean.description" | \
    ${OUTPUT_DIR}/subword-nmt/subword_nmt/learn_bpe.py -s $merge_ops > "${OUTPUT_DIR_DATA}/bpe.${merge_ops}"

  echo "Apply BPE with merge_ops=${merge_ops} to tokenized files..."
  for lang in summary description; do
    for f in ${OUTPUT_DIR_DATA}/*.tok.${lang} ${OUTPUT_DIR_DATA}/*.tok.clean.${lang}; do
      outfile="${f%.*}.bpe.${merge_ops}.${lang}"
      ${OUTPUT_DIR}/subword-nmt/subword_nmt/apply_bpe.py -c "${OUTPUT_DIR_DATA}/bpe.${merge_ops}" < $f > "${outfile}"
      echo ${outfile}
    done
  done

  # Create vocabulary file for BPE
  cat "${OUTPUT_DIR_DATA}/train.tok.clean.bpe.${merge_ops}.description" "${OUTPUT_DIR_DATA}/train.tok.clean.bpe.${merge_ops}.summary" | \
    ${OUTPUT_DIR}/subword-nmt/subword_nmt/get_vocab.py | cut -f1 -d ' ' > "${OUTPUT_DIR_DATA}/vocab.bpe.${merge_ops}"

done

echo "All done."
