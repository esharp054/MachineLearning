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

import UIKit
import CoreML

class CoreMLViewController: UIViewController, URLSessionDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    // MARK: Class Properties
    var session = URLSession()
    let operationQueue = OperationQueue()
    let motionOperationQueue = OperationQueue()
    let calibrationOperationQueue = OperationQueue()
    
    @IBOutlet weak var imageView: UIImageView!
    //    @IBOutlet weak var takePictureButton: UIButton!
//    @IBOutlet weak var imageView: UIImageView!
    let imagePicker = UIImagePickerController()
    
    @IBOutlet weak var sendPredButton: UIButton!
    @IBOutlet weak var takePictureButton: UIButton!
    @IBOutlet weak var predLabel: UILabel!
    //    @IBOutlet weak var predLabel: UILabel!
//    @IBOutlet weak var sendPredButton: UIButton!
    
    var modelRf = RandomForestAccel()
    var modelSvm = SVMAccel()
    
    var ringBuffer = RingBuffer()
    var addDataBool = false
    var sendPredBool = false
    let animation = CATransition()
    
    var photoLabel = ""
    
    
    @IBAction func sendPred(_ sender: Any) {
        
        let size = CGSize(width: 224, height: 224)
        
        let pixelBuffer = imageView.image!.resize(to: size).pixelData()
        let seq = toMLMultiArray(pixelBuffer!)
        
//        self.type(of: init)(MLMultiArray: pixelBuffer)
        //        toMLMultiArray(pixelBuffer.getDataAsVector())
//        let seq = convenience init(pixelBuffer value: MLMultiArray)
//        toMLMultiArray(pixelBuffer.getDataAsVector())
        
        guard let outputRf = try? modelRf.prediction(input: seq) else {
            fatalError("Unexpected runtime error.")
        }
        
        guard let outputSvm = try? modelSvm.prediction(input: seq) else {
            fatalError("Unexpected runtime error.")
        }
        
        displayLabelResponse(outputRf.classLabel)

        
    }

    @IBAction func takePicture(_ sender: Any) {
        imagePicker.sourceType = .camera
        imageView.isHidden = false
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.contentMode = .scaleAspectFit
            imageView.image = pickedImage
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.isHidden = true
        
        imagePicker.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
        
        let sessionConfig = URLSessionConfiguration.ephemeral
        
        sessionConfig.timeoutIntervalForRequest = 5.0
        sessionConfig.timeoutIntervalForResource = 8.0
        sessionConfig.httpMaximumConnectionsPerHost = 1
        
        self.session = URLSession(configuration: sessionConfig,
                                  delegate: self,
                                  delegateQueue:self.operationQueue)
    }
    
    func displayLabelResponse(_ response:String){
        DispatchQueue.main.async {
            self.predLabel.text = "Prediction: " + response
            self.predLabel.isHidden = false
        }
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

// convert to ML Multi array
// https://github.com/akimach/GestureAI-CoreML-iOS/blob/master/GestureAI/GestureViewController.swift
private func toMLMultiArray(_ arr: [UInt8]) -> MLMultiArray {
    guard let sequence = try? MLMultiArray(shape:[200704], dataType:MLMultiArrayDataType.double) else {
        fatalError("Unexpected runtime error. MLMultiArray could not be created")
    }
    let size = Int(truncating: sequence.shape[0])
    for i in 0..<size {
        sequence[i] = NSNumber(floatLiteral: Double(arr[i]))
    }
    return sequence
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





