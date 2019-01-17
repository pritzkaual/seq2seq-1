import os
import codecs

from timeit import default_timer as timer


def process_dataset(dataset_path, outfile_path=None, filter=None):
    # Extract all files to process from given dataset_path
    files = [dataset_path + file for file in sorted(os.listdir(dataset_path)) if filter in file]
    
    # print(files)
    
    print("Read all files and decode to 'ascii'")
    start_time = timer()
    
    if outfile_path is None:
        for fname in files:
            with codecs.open(fname + "_post.txt", "w+", "ascii") as file_writer:
                with codecs.open(fname, "r", "utf-8") as file_:
                    text = file_.read().encode(encoding="utf-8").decode(encoding="ascii", errors='ignore')
                
                file_writer.write(text + "\n")
    else:
        with codecs.open(outfile_path, "w+", "ascii") as file_writer:
            for fname in files:
                with codecs.open(fname, "r", "utf-8") as file_:
                    text = file_.read().encode(encoding="utf-8").decode(encoding="ascii", errors='ignore')
                
                file_writer.write(text + "\n")
    print("FINISH: After %s sec" % (timer() - start_time))

