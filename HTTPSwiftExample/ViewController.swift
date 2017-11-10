//
//  ViewController.swift
//  HTTPSwiftExample
//
//  Created by Eric Larson on 3/30/15.
//  Copyright (c) 2015 Eric Larson. All rights reserved.
//

// This exampe is meant to be run with the python example:
//              tornado_example.py 
//              from the course GitHub repository: tornado_bare, branch sklearn_example


// if you do not know your local sharing server name try:
//    ifconfig |grep inet   
// to see what your public facing IP address is, the ip address can be used here
//let SERVER_URL = "http://erics-macbook-pro.local:8000" // change this for your server name!!!
let SERVER_URL = "http://169.254.25.42:8000" // change this for your server name!!!

import UIKit

class ViewController: UIViewController, URLSessionDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate , UIPickerViewDelegate, UIPickerViewDataSource{
    
    // MARK: Class Properties
    var session = URLSession()
    let operationQueue = OperationQueue()
    let motionOperationQueue = OperationQueue()
    let calibrationOperationQueue = OperationQueue()
    
    @IBOutlet weak var takePictureButton: UIButton!
    @IBOutlet weak var updateButton: UIButton!
    @IBOutlet weak var modelPicker: UIPickerView!
    @IBOutlet weak var imageView: UIImageView!
    let imagePicker = UIImagePickerController()
    
    @IBOutlet weak var labelTextField: UITextField!
    @IBOutlet weak var predButton: UIButton!
    @IBOutlet weak var predLabel: UILabel!
    @IBOutlet weak var addDataButton: UIButton!
    @IBOutlet weak var sendDataButton: UIButton!
    @IBOutlet weak var sendPredButton: UIButton!
    @IBOutlet weak var returnButton: UIButton!
    @IBOutlet weak var addLabel: UILabel!
    @IBOutlet weak var changeModel: UIButton!
    @IBOutlet weak var parameterLabel: UILabel!
    @IBOutlet weak var parameterData: UITextField!
    
    var ringBuffer = RingBuffer()
    var addDataBool = false
    var sendPredBool = false
    let animation = CATransition()

    var photoLabel = ""
    var pickerData: [String] = [String]()
    var parameterdata:Float = 1.0
    
    @IBOutlet weak var dsidStepper: UIStepper!
    @IBOutlet weak var dsidLabel: UILabel!
    
    var modelInt = 0
    var dsid:Int = 0 {
        didSet{
            DispatchQueue.main.async{
                // update label when set
                self.dsidLabel.layer.add(self.animation, forKey: nil)
                self.dsidLabel.text = "Current DSID: \(self.dsid)"
            }
        }
    }

    
    func setDelayedWaitingToTrue(_ time:Double){
        DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: {
//            self.isWaitingForMotionData = true
        })
    }

    
    
    @IBAction func sendData(_ sender: Any) {
        sendFeatures(imageView.image!, label: labelTextField.text!)
        
        imageView.isHidden = true
        labelTextField.isHidden = true
        labelTextField.text = ""
        addDataButton.isHidden = false
        predButton.isHidden = false
        sendDataButton.isHidden = true
        addLabel.isHidden = true
        takePictureButton.isHidden = true
        updateButton.isHidden = false
        changeModel.isHidden = false
        
        imageView.image = nil
    }
    
  
    @IBAction func sendModelChange(_ sender: Any) {
        imageView.isHidden = true
        labelTextField.isHidden = true
        sendDataButton.isHidden = true
        sendPredButton.isHidden = true
        addLabel.isHidden = true
        predLabel.isHidden = true
        takePictureButton.isHidden = true
        updateButton.isHidden = true
        addDataButton.isHidden = true
        predButton.isHidden = true
        modelPicker.isHidden = false
        changeModel.isHidden = true
        parameterLabel.isHidden = false
        parameterData.isHidden = false
        returnButton.isHidden = false
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1;
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This method is triggered whenever the user makes a change to the picker selection.
        // The parameter named row and component represents what was selected.
        let val = pickerData[row]
        
        if(val == "SVC"){
            modelInt = 0
            parameterLabel.text = "Enter SVC Gamma Value: "
        }
        else if(val == "Random Forest"){
            modelInt = 1
            parameterLabel.text = "Enter # of Random Forest estimators: "
        }
        else if(val == "KNN"){
            modelInt = 2
            parameterLabel.text = "Enter # of KNN neighbors: "
        }
        
//        if let text = parameterData.text, !text.isEmpty
//        {
//             parameterdata = Float(parameterData.text!)!
//        }
//        else{
//             parameterdata = 0
//        }
    }
    
    @IBAction func sendPred(_ sender: Any) {
        getPrediction(imageView.image!)
        
        
        labelTextField.isHidden = true
        takePictureButton.isHidden = true
        addLabel.isHidden = true
        sendPredButton.isHidden = true
        changeModel.isHidden = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
            self.imageView.isHidden = true
            self.predLabel.isHidden = true
            self.imageView.image = nil
            
            self.addDataButton.isHidden = false
            self.predButton.isHidden = false
            self.sendDataButton.isHidden = true
            self.updateButton.isHidden = false
            self.changeModel.isHidden = false
        })
    }
    @IBAction func makePrediction(_ sender: Any) {
        imageView.isHidden = false
        labelTextField.isHidden = true
        addLabel.isHidden = true
        addDataButton.isHidden = true
        predButton.isHidden = true
        sendDataButton.isHidden = true
        takePictureButton.isHidden = false
        updateButton.isHidden = true
        changeModel.isHidden = true
        
        sendPredBool = true
    }
    @IBAction func addDataPoint(_ sender: Any) {
        imageView.isHidden = false
        labelTextField.isHidden = true
        addLabel.isHidden = true
        addDataButton.isHidden = true
        predButton.isHidden = true
        sendDataButton.isHidden = true
        takePictureButton.isHidden = false
        updateButton.isHidden = true
        changeModel.isHidden = true
        addDataBool = true
    }
    @IBAction func takePicture(_ sender: Any) {
        imagePicker.sourceType = .camera
        
        present(imagePicker, animated: true, completion: nil)
        if(addDataBool){
            labelTextField.isHidden = false
            addLabel.isHidden = false
            addDataBool = false
        }
        if(sendPredBool){
            sendPredBool = false
            sendPredButton.isHidden = false
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.contentMode = .scaleAspectFit
            imageView.image = pickedImage
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func stepperAction(_ sender: Any) {
        dsid = Int(dsidStepper.value);
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
        labelTextField.resignFirstResponder()
        parameterData.resignFirstResponder()
        if let text = labelTextField.text, !text.isEmpty
        {
            self.sendDataButton.isHidden = false
        }
        return true
    }
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.isHidden = true
        labelTextField.isHidden = true
        sendDataButton.isHidden = true
        sendPredButton.isHidden = true
        addLabel.isHidden = true
        predLabel.isHidden = true
        takePictureButton.isHidden = true
        updateButton.isHidden = true
        modelPicker.isHidden = true
        parameterData.isHidden = true
        parameterLabel.isHidden = true
        returnButton.isHidden = true
        self.modelPicker.delegate = self
        self.modelPicker.dataSource = self
        
        pickerData = ["SVC", "Random Forest", "KNN"]
        
        imagePicker.delegate = self
        labelTextField.delegate = self
        parameterData.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
        
        let sessionConfig = URLSessionConfiguration.ephemeral
        
        sessionConfig.timeoutIntervalForRequest = 5.0
        sessionConfig.timeoutIntervalForResource = 8.0
        sessionConfig.httpMaximumConnectionsPerHost = 1
        
        self.session = URLSession(configuration: sessionConfig,
            delegate: self,
            delegateQueue:self.operationQueue)
        
        dsidStepper.autorepeat = true
        dsidStepper.maximumValue = 100.0
        dsidStepper.minimumValue = 1.0
        dsid = 2 // set this and it will update UI
    }

    @IBAction func returnToMain(_ sender: Any) {
        imageView.isHidden = true
        labelTextField.isHidden = true
        sendDataButton.isHidden = true
        sendPredButton.isHidden = true
        addLabel.isHidden = true
        predLabel.isHidden = true
        changeModel.isHidden = false
        addDataButton.isHidden = false
        predButton.isHidden = false
        takePictureButton.isHidden = true
        updateButton.isHidden = false
        modelPicker.isHidden = true
        parameterData.isHidden = true
        parameterLabel.isHidden = true
        returnButton.isHidden = true
        
        if let text = parameterData.text, !text.isEmpty
        {
            parameterdata = Float(parameterData.text!)!
        }
        
    }
    
    @IBAction func getDataSetId(_ sender: AnyObject) {
        // create a GET request for a new DSID from server
        let baseURL = "\(SERVER_URL)/GetNewDatasetId"
        
        let getUrl = URL(string: baseURL)
        let request: URLRequest = URLRequest(url: getUrl!)
        let dataTask : URLSessionDataTask = self.session.dataTask(with: request,
            completionHandler:{(data, response, error) in
                if(error != nil){
                    print("Response:\n%@",response!)
                }
                else{
                    let jsonDictionary = self.convertDataToDictionary(with: data)
                    
                    // This better be an integer
                    if let dsid = jsonDictionary["dsid"]{
                        print(dsid)
                        self.dsid = dsid as! Int
                    }
                }
                
        })
        
        dataTask.resume() // start the task
        
    }
    
    //MARK: Comm with Server
    func sendFeatures(_ array:UIImage, label:String){
        let baseURL = "\(SERVER_URL)/AddDataPoint"
        let postUrl = URL(string: "\(baseURL)")
        
        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)
        
//        let imageData: NSData = UIImageJPEGRepresentation(array, 0.4)! as NSData
//        let imageStr = imageData.base64EncodedString()
        
        let size = CGSize(width: 224, height: 224)
        
        let pixelBuffer = array.resize(to: size).pixelData()
        
        // data to send in body of post request (send arguments as json)
        let jsonUpload:NSDictionary = ["feature":pixelBuffer!,
                                       "label":"\(label)",
                                       "dsid":self.dsid]
        
        
        let requestBody:Data? = self.convertDictionaryToData(with:jsonUpload)
        
        request.httpMethod = "POST"
        request.httpBody = requestBody
        
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
            completionHandler:{(data, response, error) in
                if(error != nil){
                    if let res = response{
                        print("Response:\n",res)
                    }
                }
                else{
                    let jsonDictionary = self.convertDataToDictionary(with: data)
                    
                    print(jsonDictionary["feature"]!)
                    print(jsonDictionary["label"]!)
                }

        })
        
        postTask.resume() // start the task
    }
    
    func getPrediction(_ array:UIImage){
        let baseURL = "\(SERVER_URL)/PredictOne"
        let postUrl = URL(string: "\(baseURL)")
        
        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)
        
        let size = CGSize(width: 224, height: 224)
        
        let pixelBuffer = array.resize(to: size).pixelData()
        
        // data to send in body of post request (send arguments as json)
        let jsonUpload:NSDictionary = ["feature":pixelBuffer!, "dsid":self.dsid]
        
        
        let requestBody:Data? = self.convertDictionaryToData(with:jsonUpload)
        
        request.httpMethod = "POST"
        request.httpBody = requestBody
        
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
                                                                  completionHandler:{(data, response, error) in
                                                                    if(error != nil){
                                                                        if let res = response{
                                                                            print("Response:\n",res)
                                                                        }
                                                                    }
                                                                    else{
                                                                        let jsonDictionary = self.convertDataToDictionary(with: data)
                                                                        
                                                                        let labelResponse = jsonDictionary["prediction"]!
                                                                        print(labelResponse)
                                                                        self.displayLabelResponse(labelResponse as! String)

                                                                    }
                                                                    
        })
        
        postTask.resume() // start the task
    }
    
    func displayLabelResponse(_ response:String){
        DispatchQueue.main.async {
            self.predLabel.text = "Prediction: " + response
            self.predLabel.isHidden = false
        }
    }
    
    @IBAction func makeModel(_ sender: AnyObject) {
        
        // create a GET request for server to update the ML model with current data
        let baseURL = "\(SERVER_URL)/UpdateModel"
        let query = "?dsid=\(self.dsid)"
        let query2 = "&model=\(self.modelInt)"
        let query3 = "&parameter=\(self.parameterdata)"
        
        
        let getUrl = URL(string: baseURL+query+query2+query3)
        let request: URLRequest = URLRequest(url: getUrl!)
        let dataTask : URLSessionDataTask = self.session.dataTask(with: request,
              completionHandler:{(data, response, error) in
                // handle error!
                if (error != nil) {
                    if let res = response{
                        print("Response:\n",res)
                    }
                }
                else{
                    let jsonDictionary = self.convertDataToDictionary(with: data)
                    
                    if let resubAcc = jsonDictionary["resubAccuracy"]{
                        print("Resubstitution Accuracy is", resubAcc)
                    }
                }
                
        })
        DispatchQueue.main.async {
            self.updateButton.isHidden = true
        }
        
        dataTask.resume() // start the task
        
    }
    
    //MARK: JSON Conversion Functions
    func convertDictionaryToData(with jsonUpload:NSDictionary) -> Data?{
        do { // try to make JSON and deal with errors using do/catch block
            let requestBody = try JSONSerialization.data(withJSONObject: jsonUpload, options:JSONSerialization.WritingOptions.prettyPrinted)
            return requestBody
        } catch {
            print("json error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func convertDataToDictionary(with data:Data?)->NSDictionary{
        do { // try to parse JSON and deal with errors using do/catch block
            let jsonDictionary: NSDictionary =
                try JSONSerialization.jsonObject(with: data!,
                                              options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            
            return jsonDictionary
            
        } catch {
            print("json error: \(error.localizedDescription)")
            return NSDictionary() // just return empty
        }
    }

}




