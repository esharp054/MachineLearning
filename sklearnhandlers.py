#!/usr/bin/python

from pymongo import MongoClient
import tornado.web

from tornado.web import HTTPError
from tornado.httpserver import HTTPServer
from tornado.ioloop import IOLoop
from tornado.options import define, options

from basehandler import BaseHandler

from sklearn.ensemble import RandomForestClassifier
from sklearn.svm import SVC
from sklearn.neighbors import KNeighborsClassifier
import pickle
from bson.binary import Binary
import json
import numpy as np

class PrintHandlers(BaseHandler):
    def get(self):
        '''Write out to screen the handlers used
        This is a nice debugging example!
        '''
        self.set_header("Content-Type", "application/json")
        self.write(self.application.handlers_string.replace('),','),\n'))

class UploadLabeledDatapointHandler(BaseHandler):
    def post(self):
        '''Save data point and class label to database
        '''
        data = json.loads(self.request.body.decode("utf-8"))

        vals = data['feature']
        fvals = [float(val) for val in vals]
        label = data['label']
        sess  = data['dsid']

        dbid = self.db.labeledinstances.insert(
            {"feature":fvals,"label":label,"dsid":sess}
            );
        self.write_json({"id":str(dbid),
            "feature":[str(len(fvals))+" Points Received",
                    "min of: " +str(min(fvals)),
                    "max of: " +str(max(fvals))],
            "label":label})

class UploadPreferredClassifier(BaseHandler):
    def post(self):
        '''Save data point and class label to database
            '''
        data = json.loads(self.request.body.decode("utf-8"))


class RequestNewDatasetId(BaseHandler):
    def get(self):
        '''Get a new dataset ID for building a new dataset
        '''
        a = self.db.labeledinstances.find_one(sort=[("dsid", -1)])
        if a == None:
            newSessionId = 1
        else:
            newSessionId = float(a['dsid'])+1
        self.write_json({"dsid":newSessionId})

class UpdateModelForDatasetId(BaseHandler):
    def get(self):
        '''Train a new model (or update) for given dataset ID
        '''
        dsid = self.get_int_arg("dsid",default=0)
        mod = self.get_int_arg("model", default=1)
        param = self.get_float_arg("parameter",default = 0)

        # create feature vectors from database
        f = np.array([]);
        for a in self.db.labeledinstances.find({"dsid":dsid}):
            f = np.concatenate(([float(val) for val in a['feature']], f))
        
        # create label vector from database
        l=[];
        for a in self.db.labeledinstances.find({"dsid":dsid}): 
            l.append(a['label'])

        # fit the model to the data
        
        if mod == 2:
            if param == 0.0:
                param = 15
            c1 = KNeighborsClassifier(n_neighbors=int(param));
        elif mod == 0:
            if param == 0.0:
                param = .001
            c1 = SVC(gamma=param)
        elif mod == 1:
            if param == 0.0:
                param = 10
            c1 = RandomForestClassifier(n_estimators=int(param))

        acc = -1;
        
        fShape = f.reshape(len(l), -1)
        if l:
            c1.fit(fShape,l) # training
            lstar = c1.predict(fShape)
            self.clf[dsid] = c1
            acc = sum(lstar==l)/float(len(l))
            bytes = pickle.dumps(c1)
            self.db.models.update({"dsid":dsid},
                {  "$set": {"model":Binary(bytes)}  },
                upsert=True)

        # send back the resubstitution accuracy
        # if training takes a while, we are blocking tornado!! No!!
        self.write_json({"resubAccuracy":acc})

class PredictOneFromDatasetId(BaseHandler):
    def post(self):
        '''Predict the class of a sent feature vector
        '''
        data = json.loads(self.request.body.decode("utf-8"))    

        vals = data['feature'];
        fvals = [float(val) for val in vals];
        fvals = np.array(fvals).reshape(1, -1)
        dsid  = data['dsid']

        # load the model from the database (using pickle)
        # we are blocking tornado!! no!!
        if not self.clf :
            print('Loading Model From DB')
            tmp = self.db.models.find_one({"dsid":dsid})
            self.clf[dsid] = pickle.loads(tmp['model'])
            predLabel = self.clf[dsid].predict(fvals);
            self.write_json({"prediction":str(predLabel)})
        elif dsid in self.clf.keys():
            predLabel = self.clf[dsid].predict(fvals);
            self.write_json({"prediction":str(predLabel)})
        else:
            predLabel = "No Model for this DSID";
            self.write_json({"prediction":str(predLabel)})
