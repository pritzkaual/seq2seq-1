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

DATASET_DIR=${DATASET_DIR:-/data/workspace/apritzkau/thesis/dataset/train/wiki_en}
OUTPUT_DIR=${OUTPUT_DIR:-/data/workspace/apritzkau/thesis/dataset/train/wiki_en/processed}

PREPARE_DATASET_SCRIPT=${PREPARE_DATASET_SCRIPT:-/home/apritzkau/workspace/thesis/seq2seq/pritzkaual-seq2seq/bin/data/prepare_dataset_file.py}

MAX_VOCAB_SIZE=10000000

echo "Writing to ${OUTPUT_DIR}. To change this, set the OUTPUT_DIR environment variable."

OUTPUT_DIR_DATA="${OUTPUT_DIR}/data"
OUTPUT_DIR_TMPDATA="${OUTPUT_DIR_DATA}/.tmp"

mkdir -p ${OUTPUT_DIR}
mkdir -p ${OUTPUT_DIR_DATA}
mkdir -p ${OUTPUT_DIR_TMPDATA}


# Extract everything
echo "Copy dataset to temporary data path ..."
if [ ! -f ${OUTPUT_DIR_DATA}/wiki.en ]; then
	if [ ! -f ${OUTPUT_DIR_TMPDATA}/wiki_en.txt ]; then
		cp ${DATASET_DIR}/wiki_en.txt ${OUTPUT_DIR_TMPDATA}/
	fi
	if [ ! -f ${OUTPUT_DIR_TMPDATA}/wiki_en.prep ]; then
		python ${PREPARE_DATASET_SCRIPT} --input=${OUTPUT_DIR_TMPDATA}/wiki_en.txt --output=${OUTPUT_DIR_TMPDATA}/wiki_en.prep
	fi

	cat ${OUTPUT_DIR_TMPDATA}/wiki_en.prep \
		> "${OUTPUT_DIR_DATA}/wiki.en"
	wc -l "${OUTPUT_DIR_DATA}/wiki.en"
fi

# Clone Moses
if [ ! -d "${OUTPUT_DIR}/mosesdecoder" ]; then
  echo "Cloning moses for data processing"
  git clone https://github.com/moses-smt/mosesdecoder.git "${OUTPUT_DIR}/mosesdecoder"
fi


# Tokenize data
for lang in en; do
	for prefix in wiki; do
		f=${OUTPUT_DIR_DATA}/${prefix}.${lang}
		if [ ! -f ${f%.*}.tok.${lang} ]; then
			echo "Tokenizing $f ..."
			${OUTPUT_DIR}/mosesdecoder/scripts/tokenizer/tokenizer.perl -lines 1000 -l en -b -threads 20 < $f > ${f%.*}.tok.${lang}
		fi
	done
done


# Clean all corpora
for lang in en; do
	for prefix in wiki; do
		for infix in "tok." ""; do
			f=${OUTPUT_DIR_DATA}/${prefix}.${infix}${lang}
			fbase=${f%.*}
			if [ ! -f "${fbase}.clean.${lang}" ]; then
				echo "Cleaning ${fbase} ..."
				${OUTPUT_DIR}/mosesdecoder/scripts/training/clean-corpus-n.perl $fbase ${lang} ${lang} "${fbase}.clean" 1 80
			fi
		done
	done
done

# Create character vocabulary (on tokenized data)
for infix in "tok.clean." "tok." "clean." ""; do
  for lang in en; do
		if [ ! -f ${OUTPUT_DIR_DATA}/wiki.vocab.char.${infix}${lang} ]; then
			echo "Create character vocabulary (on tokenized data) ${OUTPUT_DIR_DATA}/wiki.${infix}${lang} ..."
			python3 ${BASE_DIR}/bin/tools/generate_vocab.py --delimiter "" \
				< ${OUTPUT_DIR_DATA}/wiki.${infix}${lang} \
				> ${OUTPUT_DIR_DATA}/wiki.vocab.char.${infix}${lang}
		fi
	done
done


# Create vocabulary for SUMMARY and DESCRIPTION data
for infix in "tok.clean." "tok." "clean." ""; do
	for lang in en; do
		vocab_size=${MAX_VOCAB_SIZE::-3} # remove last n characters from MAX_VOCAB_SIZE

		if [ ! -f ${OUTPUT_DIR_DATA}/wiki.vocab.${vocab_size}k.${infix}${lang} ]; then
			echo "Create vocabulary for ${OUTPUT_DIR_DATA}/wiki.${infix}${lang}"
			python3 ${BASE_DIR}/bin/tools/generate_vocab.py \
				--max_vocab_size ${MAX_VOCAB_SIZE} \
				< ${OUTPUT_DIR_DATA}/wiki.${infix}${lang} \
				> ${OUTPUT_DIR_DATA}/wiki.vocab.${vocab_size}k.${infix}${lang}
		fi
	done
done
