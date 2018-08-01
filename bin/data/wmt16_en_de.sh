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

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

OUTPUT_DIR=${OUTPUT_DIR:-/data/workspace/apritzkau/thesis/seq2seq/nmt_data/wmt16_de_en}
echo "Writing to ${OUTPUT_DIR}. To change this, set the OUTPUT_DIR environment variable."

OUTPUT_DIR_TMPDATA="${OUTPUT_DIR}/__data"
OUTPUT_DIR_DATA="${OUTPUT_DIR}/data"

mkdir -p $OUTPUT_DIR_TMPDATA
mkdir -p $OUTPUT_DIR_DATA

if [ ! -f ${OUTPUT_DIR_TMPDATA}/europarl-v7-de-en.tgz ]; then
    echo "Downloading Europarl v7. This may take a while..."
		wget -c -nc -nv -O ${OUTPUT_DIR_TMPDATA}/europarl-v7-de-en.tgz \
			http://www.statmt.org/europarl/v7/de-en.tgz
fi
if [ ! -f ${OUTPUT_DIR_TMPDATA}/common-crawl.tgz ]; then
		echo "Downloading Common Crawl corpus. This may take a while..."
		wget -c -nc -nv -O ${OUTPUT_DIR_TMPDATA}/common-crawl.tgz \
  		http://www.statmt.org/wmt13/training-parallel-commoncrawl.tgz
fi
if [ ! -f ${OUTPUT_DIR_TMPDATA}/nc-v11.tgz ]; then
		echo "Downloading News Commentary v11. This may take a while..."
		wget -c -nc -nv -O ${OUTPUT_DIR_TMPDATA}/nc-v11.tgz \
			http://data.statmt.org/wmt16/translation-task/training-parallel-nc-v11.tgz
fi
if [ ! -f ${OUTPUT_DIR_TMPDATA}/dev.tgz ]; then
		echo "Downloading dev sets"
		wget -c -nc -nv -O  ${OUTPUT_DIR_TMPDATA}/dev.tgz \
			http://data.statmt.org/wmt16/translation-task/dev.tgz
fi
if [ ! -f ${OUTPUT_DIR_TMPDATA}/test.tgz ]; then
		echo "Downloading dev sets"
		wget -c -nc -nv -O  ${OUTPUT_DIR_TMPDATA}/test.tgz \
			http://data.statmt.org/wmt16/translation-task/test.tgz
fi

# Extract everything
if [ ! -d ${OUTPUT_DIR_TMPDATA}/test ]; then
	echo "Extracting all files..."
	mkdir -p "${OUTPUT_DIR_TMPDATA}/europarl-v7-de-en"
	tar -xvzf "${OUTPUT_DIR_TMPDATA}/europarl-v7-de-en.tgz" -C "${OUTPUT_DIR_TMPDATA}/europarl-v7-de-en"
	mkdir -p "${OUTPUT_DIR_TMPDATA}/common-crawl"
	tar -xvzf "${OUTPUT_DIR_TMPDATA}/common-crawl.tgz" -C "${OUTPUT_DIR_TMPDATA}/common-crawl"
	mkdir -p "${OUTPUT_DIR_TMPDATA}/nc-v11"
	tar -xvzf "${OUTPUT_DIR_TMPDATA}/nc-v11.tgz" -C "${OUTPUT_DIR_TMPDATA}/nc-v11"
	mkdir -p "${OUTPUT_DIR_TMPDATA}/dev"
	tar -xvzf "${OUTPUT_DIR_TMPDATA}/dev.tgz" -C "${OUTPUT_DIR_TMPDATA}/dev"
	mkdir -p "${OUTPUT_DIR_TMPDATA}/test"
	tar -xvzf "${OUTPUT_DIR_TMPDATA}/test.tgz" -C "${OUTPUT_DIR_TMPDATA}/test"
fi

# Concatenate Training data
cat "${OUTPUT_DIR_TMPDATA}/europarl-v7-de-en/europarl-v7.de-en.en" \
  "${OUTPUT_DIR_TMPDATA}/common-crawl/commoncrawl.de-en.en" \
  "${OUTPUT_DIR_TMPDATA}/nc-v11/training-parallel-nc-v11/news-commentary-v11.de-en.en" \
  > "${OUTPUT_DIR_DATA}/train.en"
wc -l "${OUTPUT_DIR_DATA}/train.en"

cat "${OUTPUT_DIR_TMPDATA}/europarl-v7-de-en/europarl-v7.de-en.de" \
  "${OUTPUT_DIR_TMPDATA}/common-crawl/commoncrawl.de-en.de" \
  "${OUTPUT_DIR_TMPDATA}/nc-v11/training-parallel-nc-v11/news-commentary-v11.de-en.de" \
  > "${OUTPUT_DIR_DATA}/train.de"
wc -l "${OUTPUT_DIR_DATA}/train.de"

# Clone Moses
if [ ! -d "${OUTPUT_DIR}/mosesdecoder" ]; then
  echo "Cloning moses for data processing"
  git clone https://github.com/moses-smt/mosesdecoder.git "${OUTPUT_DIR}/mosesdecoder"
fi

if [ ! -f ${OUTPUT_DIR}/newstest2016.en ]; then
	# Convert SGM files
	# Convert newstest2014 data into raw text format
	${OUTPUT_DIR}/mosesdecoder/scripts/ems/support/input-from-sgm.perl \
		< ${OUTPUT_DIR_TMPDATA}/dev/dev/newstest2014-deen-src.de.sgm \
		> ${OUTPUT_DIR_TMPDATA}/dev/dev/newstest2014.de
fi
if [ ! -f ${OUTPUT_DIR}/newstest2016.de ]; then
	${OUTPUT_DIR}/mosesdecoder/scripts/ems/support/input-from-sgm.perl \
		< ${OUTPUT_DIR_TMPDATA}/dev/dev/newstest2014-deen-ref.en.sgm \
		> ${OUTPUT_DIR_TMPDATA}/dev/dev/newstest2014.en
fi
if [ ! -f ${OUTPUT_DIR}/newstest2015.de ]; then
	# Convert newstest2015 data into raw text format
	${OUTPUT_DIR}/mosesdecoder/scripts/ems/support/input-from-sgm.perl \
		< ${OUTPUT_DIR_TMPDATA}/dev/dev/newstest2015-deen-src.de.sgm \
		> ${OUTPUT_DIR_TMPDATA}/dev/dev/newstest2015.de
fi
if [ ! -f ${OUTPUT_DIR}/newstest2015.en ]; then
	${OUTPUT_DIR}/mosesdecoder/scripts/ems/support/input-from-sgm.perl \
		< ${OUTPUT_DIR_TMPDATA}/dev/dev/newstest2015-deen-ref.en.sgm \
		> ${OUTPUT_DIR_TMPDATA}/dev/dev/newstest2015.en
fi
if [ ! -f ${OUTPUT_DIR}/newstest2016.en ]; then
	# Convert newstest2016 data into raw text format
	${OUTPUT_DIR}/mosesdecoder/scripts/ems/support/input-from-sgm.perl \
		< ${OUTPUT_DIR_TMPDATA}/test/test/newstest2016-deen-src.de.sgm \
		> ${OUTPUT_DIR_TMPDATA}/test/test/newstest2016.de
fi
if [ ! -f ${OUTPUT_DIR}/newstest2016.en ]; then
	${OUTPUT_DIR}/mosesdecoder/scripts/ems/support/input-from-sgm.perl \
		< ${OUTPUT_DIR_TMPDATA}/test/test/newstest2016-deen-ref.en.sgm \
		> ${OUTPUT_DIR_TMPDATA}/test/test/newstest2016.en
fi
# Copy dev/test data to output dir
cp ${OUTPUT_DIR_TMPDATA}/dev/dev/newstest20*.de ${OUTPUT_DIR_DATA}
cp ${OUTPUT_DIR_TMPDATA}/dev/dev/newstest20*.en ${OUTPUT_DIR_DATA}
cp ${OUTPUT_DIR_TMPDATA}/test/test/newstest20*.de ${OUTPUT_DIR_DATA}
cp ${OUTPUT_DIR_TMPDATA}/test/test/newstest20*.en ${OUTPUT_DIR_DATA}


# Tokenize data
for f in ${OUTPUT_DIR_DATA}/*.de; do
	if [! -f ${f%.*}.tok.de]; then
		echo "Tokenizing $f..."
		${OUTPUT_DIR}/mosesdecoder/scripts/tokenizer/tokenizer.perl -q -l de -threads 8 < $f > ${f%.*}.tok.de
	fi
done

for f in ${OUTPUT_DIR_DATA}/*.en; do
	if [! -f ${f%.*}.tok.en]; then
		echo "Tokenizing $f..."
		${OUTPUT_DIR}/mosesdecoder/scripts/tokenizer/tokenizer.perl -q -l en -threads 8 < $f > ${f%.*}.tok.en
	fi
done

# Clean all corpora
for f in ${OUTPUT_DIR_DATA}/*.en; do
  fbase=${f%.*}
  echo "Cleaning ${fbase}..."
  ${OUTPUT_DIR}/mosesdecoder/scripts/training/clean-corpus-n.perl $fbase de en "${fbase}.clean" 1 80
done

# Create character vocabulary (on tokenized data)
if [ ! -f ${OUTPUT_DIR_DATA}/vocab.tok.char.en ]; then
	python3 ${BASE_DIR}/bin/tools/generate_vocab.py --delimiter "" \
		< ${OUTPUT_DIR_DATA}/train.tok.clean.en \
		> ${OUTPUT_DIR_DATA}/vocab.tok.char.en
fi
if [ ! -f ${OUTPUT_DIR_DATA}/vocab.tok.char.de ]; then
	python3 ${BASE_DIR}/bin/tools/generate_vocab.py --delimiter "" \
		< ${OUTPUT_DIR_DATA}/train.tok.clean.de \
	  > ${OUTPUT_DIR_DATA}/vocab.tok.char.de
fi
# Create character vocabulary (on non-tokenized data)
if [ ! -f ${OUTPUT_DIR_DATA}/vocab.char.en ]; then
	python3 ${BASE_DIR}/bin/tools/generate_vocab.py --delimiter "" \
		< ${OUTPUT_DIR_DATA}/train.clean.en \
		> ${OUTPUT_DIR_DATA}/vocab.char.en
fi
if [ ! -f ${OUTPUT_DIR_DATA}/vocab.char.de ]; then
	python3 ${BASE_DIR}/bin/tools/generate_vocab.py --delimiter "" \
		< ${OUTPUT_DIR_DATA}/train.clean.de \
		> ${OUTPUT_DIR_DATA}/vocab.char.de
fi
# Create vocabulary for EN data
if [ ! -f ${OUTPUT_DIR_DATA}/vocab.50k.en ]; then
	python3 ${BASE_DIR}/bin/tools/generate_vocab.py \
		 --max_vocab_size 50000 \
		< ${OUTPUT_DIR_DATA}/train.tok.clean.en \
		> ${OUTPUT_DIR_DATA}/vocab.50k.en
fi
# Create vocabulary for DE data
if [ ! -f ${OUTPUT_DIR_DATA}/vocab.50k.de ]; then
	python3 ${BASE_DIR}/bin/tools/generate_vocab.py \
		--max_vocab_size 50000 \
		< ${OUTPUT_DIR_DATA}/train.tok.clean.de \
		> ${OUTPUT_DIR_DATA}/vocab.50k.de
fi

# Generate Subword Units (BPE)
# Clone Subword NMT
if [ ! -d "${OUTPUT_DIR}/subword-nmt" ]; then
  git clone https://github.com/rsennrich/subword-nmt.git "${OUTPUT_DIR}/subword-nmt"
fi

# Learn Shared BPE
for merge_ops in 32000; do
  echo "Learning BPE with merge_ops=${merge_ops}. This may take a while..."
  cat "${OUTPUT_DIR_DATA}/train.tok.clean.de" "${OUTPUT_DIR_DATA}/train.tok.clean.en" | \
    ${OUTPUT_DIR}/subword-nmt/subword_nmt/learn_bpe.py -s $merge_ops > "${OUTPUT_DIR_DATA}/bpe.${merge_ops}"

  echo "Apply BPE with merge_ops=${merge_ops} to tokenized files..."
  for lang in en de; do
    for f in ${OUTPUT_DIR_DATA}/*.tok.${lang} ${OUTPUT_DIR_DATA}/*.tok.clean.${lang}; do
      outfile="${f%.*}.bpe.${merge_ops}.${lang}"
      ${OUTPUT_DIR}/subword-nmt/subword_nmt/apply_bpe.py -c "${OUTPUT_DIR_DATA}/bpe.${merge_ops}" < $f > "${outfile}"
      echo ${outfile}
    done
  done

  # Create vocabulary file for BPE
  cat "${OUTPUT_DIR_DATA}/train.tok.clean.bpe.${merge_ops}.en" "${OUTPUT_DIR_DATA}/train.tok.clean.bpe.${merge_ops}.de" | \
    ${OUTPUT_DIR}/subword-nmt/subword_nmt/get_vocab.py | cut -f1 -d ' ' > "${OUTPUT_DIR_DATA}/vocab.bpe.${merge_ops}"

done

echo "All done."
