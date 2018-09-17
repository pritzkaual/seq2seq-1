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

DATASET_DIR=${DATASET_DIR:-/data/workspace/apritzkau/thesis/dataset/train/seoss}

OUTPUT_DIR=${OUTPUT_DIR:-/data/workspace/apritzkau/thesis/seq2seq/nmt_data/seoss}

MAX_VOCAB_SIZE=100000

echo "Writing to ${OUTPUT_DIR}. To change this, set the OUTPUT_DIR environment variable."

OUTPUT_DIR_DATA="${OUTPUT_DIR}/data"
OUTPUT_DIR_TMPDATA="${OUTPUT_DIR_DATA}/.tmp"

mkdir -p ${OUTPUT_DIR_DATA}
mkdir -p ${OUTPUT_DIR_TMPDATA}


# Extract everything
echo "Copy dataset to temporary data path ..."
mkdir -p "${OUTPUT_DIR_TMPDATA}"
cp ${DATASET_DIR}/seoss.* ${OUTPUT_DIR_TMPDATA}/

# Concatenate Training and Test data
for lang in summary description; do
	for prefix in test train; do
		cat "${OUTPUT_DIR_TMPDATA}/seoss.${prefix}.issue.${lang}"\
			> "${OUTPUT_DIR_DATA}/${prefix}.${lang}"
		wc -l "${OUTPUT_DIR_DATA}/${prefix}.${lang}"
	done
done
cat "${OUTPUT_DIR_TMPDATA}/seoss.txt"\
  > "${OUTPUT_DIR_DATA}/seoss.txt"
wc -l "${OUTPUT_DIR_DATA}/seoss.txt"

#cat "${OUTPUT_DIR_TMPDATA}/train_issue_description.txt"\
#  > "${OUTPUT_DIR_DATA}/train.description"
#wc -l "${OUTPUT_DIR_DATA}/train.description"

#cat "${OUTPUT_DIR_TMPDATA}/train_issue_summary.txt"\
#  > "${OUTPUT_DIR_DATA}/train.summary"
#wc -l "${OUTPUT_DIR_DATA}/train.summary"

# Concatenate Test data
#cat "${OUTPUT_DIR_TMPDATA}/test_issue_description.txt"\
#  > "${OUTPUT_DIR_DATA}/test.description"
#wc -l "${OUTPUT_DIR_DATA}/test.description"

#cat "${OUTPUT_DIR_TMPDATA}/test_issue_summary.txt"\
#  > "${OUTPUT_DIR_DATA}/test.summary"
#wc -l "${OUTPUT_DIR_DATA}/test.summary"


# Clone Moses
if [ ! -d "${OUTPUT_DIR}/mosesdecoder" ]; then
  echo "Cloning moses for data processing"
  git clone https://github.com/moses-smt/mosesdecoder.git "${OUTPUT_DIR}/mosesdecoder"
fi


# Tokenize data
for lang in summary description; do
	for prefix in test train; do
		f=${OUTPUT_DIR_DATA}/${prefix}.${lang}
		if [ ! -f ${f%.*}.tok.${lang} ]; then
			echo "Tokenizing $f ..."
			${OUTPUT_DIR}/mosesdecoder/scripts/tokenizer/tokenizer.perl -q -l en -threads 20 < $f > ${f%.*}.tok.${lang}
		fi
	done
done

for lang in txt; do
	for prefix in seoss; do
		f=${OUTPUT_DIR_DATA}/${prefix}.${lang}
		if [ ! -f ${f%.*}.tok.${lang} ]; then
			echo "Tokenizing $f ..."
			${OUTPUT_DIR}/mosesdecoder/scripts/tokenizer/tokenizer.perl -q -l en -threads 20 < $f > ${f%.*}.tok.${lang}
		fi
	done
done

#for f in ${OUTPUT_DIR_DATA}/*.description; do
#	echo "Tokenizing $f..."
#	${OUTPUT_DIR}/mosesdecoder/scripts/tokenizer/tokenizer.perl -q -l en -threads 8 < $f > ${f%.*}.tok.description
#done

# Clean all corpora
for prefix in test train; do
	for infix in "tok." ""; do
		f=${OUTPUT_DIR_DATA}/${prefix}.${infix}description
		fbase=${f%.*}
		if [ ! -f "${fbase}.clean.description" ]; then
			echo "Cleaning ${fbase} ..."
			${OUTPUT_DIR}/mosesdecoder/scripts/training/clean-corpus-n.perl $fbase summary description "${fbase}.clean" 1 80
		fi
	done
done

for prefix in seoss; do
	for infix in "tok." ""; do
		f=${OUTPUT_DIR_DATA}/${prefix}.${infix}txt
		fbase=${f%.*}
		if [ ! -f "${fbase}.clean.txt" ]; then
			echo "Cleaning ${fbase} ..."
			${OUTPUT_DIR}/mosesdecoder/scripts/training/clean-corpus-n.perl $fbase txt txt "${fbase}.clean" 1 80
		fi
	done
done

# Create character vocabulary (on tokenized data)
for infix in "tok.clean." "tok." "clean." ""; do
  for lang in summary description; do
		if [ ! -f ${OUTPUT_DIR_DATA}/seq2seq.vocab.char.${infix}${lang} ]; then
			echo "Create character vocabulary (on tokenized data) ${OUTPUT_DIR_DATA}/train.${infix}${lang} ..."
			python3 ${BASE_DIR}/bin/tools/generate_vocab.py --delimiter "" \
				< ${OUTPUT_DIR_DATA}/train.${infix}${lang} \
				> ${OUTPUT_DIR_DATA}/seq2seq.vocab.char.${infix}${lang}
		fi
	done

	for lang in txt; do
		if [ ! -f ${OUTPUT_DIR_DATA}/seoss.vocab.char.${infix}${lang} ]; then
			echo "Create character vocabulary (on tokenized data) ${OUTPUT_DIR_DATA}/seoss.${infix}${lang} ..."
			python3 ${BASE_DIR}/bin/tools/generate_vocab.py --delimiter "" \
				< ${OUTPUT_DIR_DATA}/seoss.${infix}${lang} \
				> ${OUTPUT_DIR_DATA}/seoss.vocab.char.${infix}${lang}
		fi
	done
done


#if [ ! -f ${OUTPUT_DIR_DATA}/vocab.tok.char.description ]; then
#	python3 ${BASE_DIR}/bin/tools/generate_vocab.py --delimiter "" \
#		< ${OUTPUT_DIR_DATA}/train.tok.clean.description \
#		> ${OUTPUT_DIR_DATA}/vocab.tok.char.description
#fi
#if [ ! -f ${OUTPUT_DIR_DATA}/vocab.tok.char.summary ]; then
#	python3 ${BASE_DIR}/bin/tools/generate_vocab.py --delimiter "" \
#		< ${OUTPUT_DIR_DATA}/train.tok.clean.summary \
#	  > ${OUTPUT_DIR_DATA}/vocab.tok.char.summary
#fi

# Create character vocabulary (on non-tokenized data)
#if [ ! -f ${OUTPUT_DIR_DATA}/vocab.char.description ]; then
#	python3 ${BASE_DIR}/bin/tools/generate_vocab.py --delimiter "" \
#		< ${OUTPUT_DIR_DATA}/train.clean.description \
#		> ${OUTPUT_DIR_DATA}/vocab.char.description
#fi
#if [ ! -f ${OUTPUT_DIR_DATA}/vocab.char.summary ]; then
#	python3 ${BASE_DIR}/bin/tools/generate_vocab.py --delimiter "" \
#		< ${OUTPUT_DIR_DATA}/train.clean.summary \
#		> ${OUTPUT_DIR_DATA}/vocab.char.summary
#fi

# Create vocabulary for SUMMARY and DESCRIPTION data
for infix in "tok.clean." "tok." "clean." ""; do

	for lang in summary description; do
		vocab_size=${MAX_VOCAB_SIZE::-3} # remove last n characters from MAX_VOCAB_SIZE

		if [ ! -f ${OUTPUT_DIR_DATA}/seq2seq.vocab.${vocab_size}k.${infix}${lang} ]; then
			echo "Create vocabulary for ${OUTPUT_DIR_DATA}/train.${infix}${lang}"
			python3 ${BASE_DIR}/bin/tools/generate_vocab.py \
				--max_vocab_size ${MAX_VOCAB_SIZE} \
				< ${OUTPUT_DIR_DATA}/train.${infix}${lang} \
				> ${OUTPUT_DIR_DATA}/seq2seq.vocab.${vocab_size}k.${infix}${lang}
		fi
	done

	for lang in txt; do
		vocab_size=${MAX_VOCAB_SIZE::-3} # remove last n characters from MAX_VOCAB_SIZE

		if [ ! -f ${OUTPUT_DIR_DATA}/seoss.vocab.${vocab_size}k.${infix}${lang} ]; then
			echo "Create vocabulary for ${OUTPUT_DIR_DATA}/seoss.${infix}${lang}"
			python3 ${BASE_DIR}/bin/tools/generate_vocab.py \
				--max_vocab_size ${MAX_VOCAB_SIZE} \
				< ${OUTPUT_DIR_DATA}/seoss.${infix}${lang} \
				> ${OUTPUT_DIR_DATA}/seoss.vocab.${vocab_size}k.${infix}${lang}
		fi
	done
done


#if [ ! -f ${OUTPUT_DIR_DATA}/vocab.50k.description ]; then
#	vocab_size = ${MAX_VOCAB_SIZE}/1000
#	python3 ${BASE_DIR}/bin/tools/generate_vocab.py \
#		 --max_vocab_size ${MAX_VOCAB_SIZE} \
#		< ${OUTPUT_DIR_DATA}/train.${infix}description \
#		> ${OUTPUT_DIR_DATA}/vocab.${vocab_size}k.${infix}description
#fi
# Create vocabulary for SUMMARY data
#if [ ! -f ${OUTPUT_DIR_DATA}/vocab.50k.summary ]; then
#	python3 ${BASE_DIR}/bin/tools/generate_vocab.py \
#		--max_vocab_size ${MAX_VOCAB_SIZE} \
#		< ${OUTPUT_DIR_DATA}/train.tok.clean.summary \
#		> ${OUTPUT_DIR_DATA}/vocab.50k.clean.summary
#fi

# Create vocabulary for DESCRIPTION data
#if [ ! -f ${OUTPUT_DIR_DATA}/vocab.50k.description ]; then
#	python3 ${BASE_DIR}/bin/tools/generate_vocab.py \
#		 --max_vocab_size ${MAX_VOCAB_SIZE} \
#		< ${OUTPUT_DIR_DATA}/train.tok.description \
#		> ${OUTPUT_DIR_DATA}/vocab.50k.description
#fi
# Create vocabulary for SUMMARY data
#if [ ! -f ${OUTPUT_DIR_DATA}/vocab.50k.summary ]; then
#	python3 ${BASE_DIR}/bin/tools/generate_vocab.py \
#		--max_vocab_size ${MAX_VOCAB_SIZE} \
#		< ${OUTPUT_DIR_DATA}/train.tok.summary \
#		> ${OUTPUT_DIR_DATA}/vocab.50k.summary
#fi

# Generate Subword Units (BPE)
# Clone Subword NMT
if [ ! -d "${OUTPUT_DIR}/subword-nmt" ]; then
  git clone https://github.com/rsennrich/subword-nmt.git "${OUTPUT_DIR}/subword-nmt"
fi

# Learn Shared BPE
for merge_ops in 32000 64000 96000 128000; do
  echo "Learning BPE with merge_ops=${merge_ops}. This may take a while..."
	for infix in "tok.clean." "tok." "clean." ""; do
		if [ ! -d "${OUTPUT_DIR_DATA}/seq2seq.bpe.${infix}${merge_ops}" ]; then
			cat "${OUTPUT_DIR_DATA}/train.${infix}summary" "${OUTPUT_DIR_DATA}/train.${infix}description" | \
				${OUTPUT_DIR}/subword-nmt/subword_nmt/learn_bpe.py -s $merge_ops > "${OUTPUT_DIR_DATA}/seq2seq.bpe.${infix}${merge_ops}"
		fi

		if [ ! -d "${OUTPUT_DIR_DATA}/seoss.bpe.${infix}${merge_ops}" ]; then
			cat "${OUTPUT_DIR_DATA}/seoss.${infix}txt" | \
				${OUTPUT_DIR}/subword-nmt/subword_nmt/learn_bpe.py -s $merge_ops > "${OUTPUT_DIR_DATA}/seoss.bpe.${infix}${merge_ops}"
		fi
	done

  #cat "${OUTPUT_DIR_DATA}/train.tok.summary" "${OUTPUT_DIR_DATA}/train.tok.description" | \
  #  ${OUTPUT_DIR}/subword-nmt/subword_nmt/learn_bpe.py -s $merge_ops > "${OUTPUT_DIR_DATA}/bpe.tok.${merge_ops}"

  #cat "${OUTPUT_DIR_DATA}/train.clean.summary" "${OUTPUT_DIR_DATA}/train.clean.description" | \
  #  ${OUTPUT_DIR}/subword-nmt/subword_nmt/learn_bpe.py -s $merge_ops > "${OUTPUT_DIR_DATA}/bpe.clean.${merge_ops}"

  #cat "${OUTPUT_DIR_DATA}/train.summary" "${OUTPUT_DIR_DATA}/train.description" | \
  #  ${OUTPUT_DIR}/subword-nmt/subword_nmt/learn_bpe.py -s $merge_ops > "${OUTPUT_DIR_DATA}/bpe.${merge_ops}"

  echo "Apply BPE with merge_ops=${merge_ops} to tokenized files..."
	for infix in "tok.clean." "tok." "clean." ""; do
	  for lang in summary description; do
			for prefix in test train; do
				f="${OUTPUT_DIR_DATA}/${prefix}.${infix}${lang}"
				outfile="${f%.*}.bpe.${merge_ops}.${lang}"
				if [ ! -d "${outfile}" ]; then
					${OUTPUT_DIR}/subword-nmt/subword_nmt/apply_bpe.py -c "${OUTPUT_DIR_DATA}/seq2seq.bpe.${infix}${merge_ops}" < $f > "${outfile}"
				fi
			done
		done
		#
		for lang in txt; do
			for prefix in seoss; do
				f="${OUTPUT_DIR_DATA}/${prefix}.${infix}${lang}"
				outfile="${f%.*}.bpe.${merge_ops}.${lang}"
				if [ ! -d "${outfile}" ]; then
					${OUTPUT_DIR}/subword-nmt/subword_nmt/apply_bpe.py -c "${OUTPUT_DIR_DATA}/seoss.bpe.${infix}${merge_ops}" < $f > "${outfile}"
				fi
			done
		done
	done

  # Create vocabulary file for BPE
  for infix in "tok.clean." "tok." "clean." ""; do
  	if [ ! -d "${OUTPUT_DIR_DATA}/seq2seq.vocab.${infix}bpe.${merge_ops}" ]; then
			cat "${OUTPUT_DIR_DATA}/train.${infix}bpe.${merge_ops}.description" "${OUTPUT_DIR_DATA}/train.${infix}bpe.${merge_ops}.summary" | \
				${OUTPUT_DIR}/subword-nmt/subword_nmt/get_vocab.py | cut -f1 -d ' ' > "${OUTPUT_DIR_DATA}/seq2seq.vocab.${infix}bpe.${merge_ops}"
		fi

		if [ ! -d "${OUTPUT_DIR_DATA}/seoss.vocab.${infix}bpe.${merge_ops}" ]; then
			cat "${OUTPUT_DIR_DATA}/seoss.${infix}bpe.${merge_ops}.txt" | \
				${OUTPUT_DIR}/subword-nmt/subword_nmt/get_vocab.py | cut -f1 -d ' ' > "${OUTPUT_DIR_DATA}/seoss.vocab.${infix}bpe.${merge_ops}"
		fi
	done
  #cat "${OUTPUT_DIR_DATA}/train.tok.bpe.${merge_ops}.description" "${OUTPUT_DIR_DATA}/train.tok.bpe.${merge_ops}.summary" | \
  #  ${OUTPUT_DIR}/subword-nmt/subword_nmt/get_vocab.py | cut -f1 -d ' ' > "${OUTPUT_DIR_DATA}/vocab.tok.bpe.${merge_ops}"

  #cat "${OUTPUT_DIR_DATA}/train.clean.bpe.${merge_ops}.description" "${OUTPUT_DIR_DATA}/train.clean.bpe.${merge_ops}.summary" | \
  #  ${OUTPUT_DIR}/subword-nmt/subword_nmt/get_vocab.py | cut -f1 -d ' ' > "${OUTPUT_DIR_DATA}/vocab.clean.bpe.${merge_ops}"

  #cat "${OUTPUT_DIR_DATA}/train.bpe.${merge_ops}.description" "${OUTPUT_DIR_DATA}/train.bpe.${merge_ops}.summary" | \
  #  ${OUTPUT_DIR}/subword-nmt/subword_nmt/get_vocab.py | cut -f1 -d ' ' > "${OUTPUT_DIR_DATA}/vocab.bpe.${merge_ops}"

done

echo "All done."
