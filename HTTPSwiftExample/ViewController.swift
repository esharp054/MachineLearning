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
let SERVER_URL = "http://192.168.50.72:8000" // change this for your server name!!!

import UIKit

class ViewController: UIViewController, URLSessionDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    // MARK: Class Properties
    var session = URLSession()
    let operationQueue = OperationQueue()
    let motionOperationQueue = OperationQueue()
    let calibrationOperationQueue = OperationQueue()
    
    @IBOutlet weak var takePictureButton: UIButton!
    @IBOutlet weak var updateButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    let imagePicker = UIImagePickerController()
    
    @IBOutlet weak var labelTextField: UITextField!
    @IBOutlet weak var predButton: UIButton!
    @IBOutlet weak var predLabel: UILabel!
    @IBOutlet weak var addDataButton: UIButton!
    @IBOutlet weak var sendDataButton: UIButton!
    @IBOutlet weak var sendPredButton: UIButton!
    @IBOutlet weak var addLabel: UILabel!
    var ringBuffer = RingBuffer()
    var addDataBool = false
    var sendPredBool = false
    let animation = CATransition()

    var photoLabel = ""
    
    @IBOutlet weak var dsidStepper: UIStepper!
    @IBOutlet weak var dsidLabel: UILabel!
    
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
        
        imageView.image = nil
    }

    @IBAction func sendPred(_ sender: Any) {
        getPrediction(imageView.image!)
        
        
        labelTextField.isHidden = true
        takePictureButton.isHidden = true
        addLabel.isHidden = true
        sendPredButton.isHidden = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
            self.imageView.isHidden = true
            self.predLabel.isHidden = true
            self.imageView.image = nil
            
            self.addDataButton.isHidden = false
            self.predButton.isHidden = false
            self.sendDataButton.isHidden = true
            self.updateButton.isHidden = false
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
        
        
        
        imagePicker.delegate = self
        labelTextField.delegate = self
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

    //MARK: Get New Dataset ID
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
        
        let getUrl = URL(string: baseURL+query)
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

extension UIImage {
    func resize(to newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: newSize.width, height: newSize.height), true, 1.0)
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    func pixelData() -> [UInt8]? {
        
        let size = self.size
        let dataSize = size.width * size.height * 4
        var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: &pixelData,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: 4 * Int(size.width),
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        guard let cgImage = self.cgImage else { return nil }
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        return pixelData
    }
}




