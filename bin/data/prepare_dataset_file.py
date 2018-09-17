
import tensorflow as tf

import logging
import os
import re
import codecs
from unidecode import unidecode
from timeit import default_timer as timer


tf.flags.DEFINE_string("input", None,
                       """ """)
tf.flags.DEFINE_integer("output", None,
                        """ """)

FLAGS = tf.flags.FLAGS

#
filters_pattern='"#$%&()*+,-/:;<=>@[\]^_`{|}~'
filters_pattern = ['\{}'.format(ch) for ch in filters_pattern]
filters_pattern = '|'.join(filters_pattern)
#print(filters_pattern)
filters = re.compile(filters_pattern, re.MULTILINE)


def replace(string, lower=True):
    #print(type(string))
    #string = string.encode("ascii", "ignore").decode('ascii')

    string = unidecode(string)
    
    string = filters.sub(" ", string)
    string = string.replace('\n', '').replace('\r', '').replace('\t', ' ')
    #string = string.replace('_', " ").replace('-', " ")
    string = string.replace('. . .', '.').replace('. .', '.').replace(' . ', '.')
    string = string.replace('...', '.').replace('..', '.')
    string = string.replace('.', ' .\n').replace('!', ' !\n').replace('?', ' ?\n')
    string = string.replace("'", " ")
    #string = string.replace('\x0b', ' ')
    
    string = string.replace('   ', ' ').replace('  ', ' ').replace('  ', ' ').strip()
    if lower:
        string = string.lower()
    return string


def chars_from_file(filename, chunksize=1024*1024):
  with codecs.open(filename, mode='r') as f:
    while True:
      chunk = f.read(chunksize)
      if chunk:
          yield chunk
      else:
        break


# example:


def main(unused_argv=None):
  logging.basicConfig(format='%(levelname)s : %(message)s', level=logging.INFO)
  
  try:
    print("Load '{}'".format(FLAGS.input))
    start_time = timer()
    
    if FLAGS.input is None:
      raise AttributeError("Given parameter '--input' needs valid filepath.")
    
    if not os.path.isfile(FLAGS.input):
      raise FileNotFoundError("Given value '--input' '{}' is not a file.".format(FLAGS.input))
    
    if not os.path.exists(FLAGS.input):
      raise FileNotFoundError("Given file '{}' does not exists.".format(FLAGS.input))
    
    if FLAGS.output is None:
      FLAGS.output = FLAGS.input.rsplit(".", maxsplit=1)[0] + ".prep"
      logging.warning("Parameter '--output' is not given, so store results to '{}'".format(FLAGS.output))
    
    #
    os.makedirs(FLAGS.output.rsplit(os.sep, maxsplit=1)[0], exist_ok=True)
    
    #with codecs.open(FLAGS.input, mode='r') as f_in:
    with codecs.open(FLAGS.output, mode='w', encoding='ascii') as f_out:
      for chunk in chars_from_file(FLAGS.input):
  
        line = replace(chunk)
    
        f_out.write(line)
    
    print("FINISH: After %s sec" % (timer() - start_time))
  
  except Exception as e:
    logging.error("{0}".format(e))


if __name__ == '__main__':
  tf.app.run()
