#!/usr/bin/python
'''Read from PyMongo, make simply model and export for CoreML'''

# make this work nice when support for python 3 releases
from __future__ import print_function

# database imports
from pymongo import MongoClient
from pymongo.errors import ServerSelectionTimeoutError

# model imports
from sklearn.ensemble import RandomForestClassifier
from sklearn.svm import SVC
from sklearn.neighbors import KNeighborsClassifier

import numpy as np

# export
import coremltools


dsid = 2
client  = MongoClient(serverSelectionTimeoutMS=50)
db = client.sklearndatabase


# create feature/label vectors from database
y=[];
f = np.array([]);
for a in db.labeledinstances.find({"dsid":dsid}):
    f = np.concatenate(([float(val) for val in a['feature']], f))
    y.append(a['label'])


X = f.reshape(len(y), -1)
print("Found",len(y),"labels and",len(X),"feature vectors")
print("Unique classes found:",np.unique(y))

clf = RandomForestClassifier(n_estimators=150)
clf_svm = SVC()

print("Training Model", clf)

clf.fit(X,y)
clf_svm.fit(X,y)

print("Exporting to CoreML")

coreml_model = coremltools.converters.sklearn.convert(
	clf)

# save out as a file
coreml_model.save('RandomForestAccel.mlmodel')


coreml_model = coremltools.converters.sklearn.convert(
	clf_svm)

# save out as a file
coreml_model.save('SVMAccel.mlmodel')


# save out as a file

client.close()
