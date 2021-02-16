# NOT FUNCTIONAL, WIP

# DONT USE


import sys, zipfile, json
from PIL import Image
import xml.etree.ElementTree as ET
#import StringIO
HEAD = '{http://www.calligra.org/DTD/krita}'
def clean_head(child):
    return child.tag.replace(HEAD, "")

def recurse(d):
    key = clean_head(d)
    data = dict(d.attrib)
    data["__type"] = key
    children = []
    for child in d:
        children.append(recurse(child))
    if len(children) > 0:
        data["__children"] = children
    return data

    #sys.exit('Usage: '+sys.argv[0]+' <Input> <Output> <Size>')

zipf = zipfile.ZipFile("./block.kra")
maindoc = ET.ElementTree(ET.fromstring(zipf.read("maindoc.xml")))
#print(maindoc.getroot()[0].attrib)

data = recurse(maindoc.getroot(), 0)
print(json.dumps(data, indent=4))

#for child in maindoc.getroot():
    #key = clean_head(child)
    #print(key)
    #if key == "layers":
        #print(child[0].attrib["name"])
        #for layer in child[0][0]:
            #print("\t", clean_head(layer), layer.attrib['name'])

#.read('preview.png')

#im = Image.open(StringIO.StringIO(thumbnail))
#im.thumbnail( (int(sys.argv[3]), int(sys.argv[3])) )

#im.save(sys.argv[2],'png')



















"""
NOT USABLE AT ALL
probably never will be
"""

import glob
import os

import krita
from PyQt5 import QtWidgets


IMAGES_FILEPATH = QtWidgets.QFileDialog.getExistingDirectory()
FILEPATHS = sorted(glob.glob(IMAGES_FILEPATH + '/*'))
print(FILEPATHS)


def open_document(filepath, show=True):
	"""Open the given filepath as new document
	Arguments:
		filepath (str): the filepath of the image to open
		show (bool): should the image get shown in the Krita UI?
	"""
	
	k = krita.Krita.instance()
	print('Debug: opening %s' % filepath)
	doc = k.openDocument(filepath)
	if show:
		Application.activeWindow().addView(doc)
	return doc


def get_layers(doc):
	"""Return layers for given document"""
	nodes = []
	root = doc.rootNode()
	for node in root.childNodes():
		print('Debug: found node of type %s: %s' % (node.type(), node.name()))
		if node.type() == "paintlayer":
			nodes.append(node)
	return nodes



def make_layered_psd_from_images():
	"""Takes a folderpath, scans it for images and produces a layered image"""

	
	doc = open_document(FILEPATHS[0], show=False)
	doc_root = doc.rootNode()
	
	docs = []
	docs.append(doc)

	all_layers = get_layers(doc)
	for i in range(1, len(FILEPATHS)):
		docx = open_document(FILEPATHS[i], show=False)
		docs.append(docx)
		docx_layers = get_layers(docx)
		for layer in docx_layers:
			all_layers.append(layer.clone())
			# doc.rootNode().addChildNode(layer, parent_node)
	doc_root.setChildNodes(all_layers)

	print('Debug: all nodes: %s' % doc.rootNode().childNodes())
	# doc.refreshProjection()

	save_filepath = filepath = QtWidgets.QFileDialog.getSaveFileName()[0]
	r = doc.saveAs(save_filepath)
	print('Debug: saved: %s' % save_filepath)
	
	for doc in docs:
		print('Debug: closing %s' % doc)
		doc.close()

	print('Debug: Script done')


# make_layered_psd_from_images()






# # from krita import *
# # print(Krita.instance().filters())

# import zipfile
# import os
# #import PIL
# # from lxml import etree as ET
# import xml.etree.ElementTree as ET
# # tree = ET.ElementTree(ET.fromstring(xmlstring))


# # https://github.com/bloodywing/kraconvert/blob/master/kraconvert/kra.py

# def func():
# 	krafile = "./world_map.kra"
# 	kra = zipfile.ZipFile(krafile)

# 	filename = os.path.basename(krafile)
# 	basename, _ = filename.split('.')
	
# 	for k in kra.filelist:
# 		print(k)

# 	print(ET.fromstring(kra.read("maindoc.xml")["{http://www.calligra.org/DTD/krita}DOC"]))
# 	# merged_image = kra.read('mergedimage.png')

# 	# self.xml = ET.fromstring(kra.read('maindoc.xml'))
# 	# self.kra_name = self.xml.find('.//kra:IMAGE', ns).attrib['name']

# 	# self.icc = kra.read('{basename}/annotations/icc'.format(basename=self.kra_name))


# func()