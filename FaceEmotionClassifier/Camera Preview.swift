//
//  Camera Preview.swift
//  FaceEmotionClassifier
//
//  Created by Sharan Thakur on 16/03/24.
//

import AVFoundation
import Observation
import SwiftUI

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreview {
        let view = CameraPreview()
        view.backgroundColor = .black
        view.videoPreviewLayerView.session = session
        view.videoPreviewLayerView.videoGravity = .resizeAspect
        view.videoPreviewLayerView.connection?.videoOrientation = .portrait
        return view
    }
    
    func updateUIView(_ uiView: CameraPreview, context: Context) {
        
    }
}

class CameraPreview: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayerView: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

@Observable
class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var status: AVAuthorizationStatus
    var videoDeviceInput: AVCaptureDeviceInput?
    
    let session = AVCaptureSession()
    private let videoDeviceOutput = AVCaptureVideoDataOutput()
    private let classifier = try! Face_Emotion_Classifier(configuration: .init())
    
    var didOutput: ((Array<(String, Double)>?) -> Void)?
    
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    
    override init() {
        self.status = AVCaptureDevice.authorizationStatus(for: .video)
        super.init()
        videoDeviceOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        request()
    }
    
    func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.status == .authorized else { return }
            
            self.session.beginConfiguration()
            self.session.sessionPreset = .hd1280x720
            self.setupVideoInput()
            self.session.commitConfiguration()
            self.startCapturing()
        }
    }
    
    func request() {
        AVCaptureDevice.requestAccess(for: .video) { _ in
            self.status = AVCaptureDevice.authorizationStatus(for: .video)
        }
    }
    
    // Method to set up video input from the camera
    private func setupVideoInput() {
        do {
            // Get the default wide-angle camera for video capture
            // AVCaptureDevice is a representation of the hardware device to use
            let position: AVCaptureDevice.Position = .front
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
            
            guard let camera else {
                print("CameraManager: Video device is unavailable.")
                session.commitConfiguration()
                return
            }
            
            // Create an AVCaptureDeviceInput from the camera
            let videoInput = try AVCaptureDeviceInput(device: camera)
            
            // Add video input to the session if possible
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
                videoDeviceInput = videoInput
            } else {
                print("CameraManager: Couldn't add video device input to the session.")
                session.commitConfiguration()
                return
            }
            
            if session.canAddOutput(videoDeviceOutput) {
                session.addOutput(videoDeviceOutput)
            } else {
                print("CameraManager: Couldn't add video device output to the session.")
                session.commitConfiguration()
                return
            }
        } catch {
            print("CameraManager: Couldn't create video device input: \(error)")
            session.commitConfiguration()
            return
        }
    }
    
    // Method to start capturing
    private func startCapturing() {
        if status == .authorized {
            // Start running the capture session
            self.session.startRunning()
        } else {
            
        }
    }
    
    func stopCapturing() {
        self.session.stopRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let buffer = sampleBuffer.imageBuffer else {
            return
        }
        let input = Face_Emotion_ClassifierInput(image: buffer)
        do {
            let output = try classifier.prediction(input: input)
            let probabilities = output.targetProbability.map { $0 }.sorted {
                $0.value > $1.value
            }
            self.didOutput?(probabilities)
        } catch {
            print(error)
        }
    }
}
