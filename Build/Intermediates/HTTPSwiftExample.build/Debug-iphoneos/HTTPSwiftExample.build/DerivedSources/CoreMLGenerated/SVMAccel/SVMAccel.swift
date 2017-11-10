//
// SVMAccel.swift
//
// This file was automatically generated and should not be edited.
//

import CoreML


/// Model Prediction Input Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class SVMAccelInput : MLFeatureProvider {

    /// input as 200704 element vector of doubles
    var input: MLMultiArray
    
    var featureNames: Set<String> {
        get {
            return ["input"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "input") {
            return MLFeatureValue(multiArray: input)
        }
        return nil
    }
    
    init(input: MLMultiArray) {
        self.input = input
    }
}


/// Model Prediction Output Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class SVMAccelOutput : MLFeatureProvider {

    /// classLabel as string value
    let classLabel: String
    
    var featureNames: Set<String> {
        get {
            return ["classLabel"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "classLabel") {
            return MLFeatureValue(string: classLabel)
        }
        return nil
    }
    
    init(classLabel: String) {
        self.classLabel = classLabel
    }
}


/// Class for model loading and prediction
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class SVMAccel {
    var model: MLModel

    /**
        Construct a model with explicit path to mlmodel file
        - parameters:
           - url: the file url of the model
           - throws: an NSError object that describes the problem
    */
    init(contentsOf url: URL) throws {
        self.model = try MLModel(contentsOf: url)
    }

    /// Construct a model that automatically loads the model from the app's bundle
    convenience init() {
        let bundle = Bundle(for: SVMAccel.self)
        let assetPath = bundle.url(forResource: "SVMAccel", withExtension:"mlmodelc")
        try! self.init(contentsOf: assetPath!)
    }

    /**
        Make a prediction using the structured interface
        - parameters:
           - input: the input to the prediction as SVMAccelInput
        - throws: an NSError object that describes the problem
        - returns: the result of the prediction as SVMAccelOutput
    */
    func prediction(input: SVMAccelInput) throws -> SVMAccelOutput {
        let outFeatures = try model.prediction(from: input)
        let result = SVMAccelOutput(classLabel: outFeatures.featureValue(for: "classLabel")!.stringValue)
        return result
    }

    /**
        Make a prediction using the convenience interface
        - parameters:
            - input as 200704 element vector of doubles
        - throws: an NSError object that describes the problem
        - returns: the result of the prediction as SVMAccelOutput
    */
    func prediction(input: MLMultiArray) throws -> SVMAccelOutput {
        let input_ = SVMAccelInput(input: input)
        return try self.prediction(input: input_)
    }
}
