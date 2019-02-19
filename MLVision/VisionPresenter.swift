//
//  VisionPresenter.swift
//  MLVision
//
//  Created by Hakeem Hasan on 1/24/19.
//  Copyright © 2019 Nasah Apps, LLC. All rights reserved.
//

import Vision
import AVFoundation
import UIKit

protocol VisionPresenterDelegate {
    func onBarcodeScanned(_ barcodes: [VNBarcodeObservation])
}

class VisionPresenter : NSObject {
    
    let captureSession = AVCaptureSession()
    
    var delegate: VisionPresenterDelegate? = nil
    
    /**
        Checks if the app has permission to use the camera. If not, it requests it from the user
 
        - Parameter callback: block to be executed after checking permission. Will contain a Bool that says whether permission was granted or not
     */
    func checkCameraPermission(callback: @escaping (_ granted: Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("Camera authorized")
            callback(true)
        case .notDetermined:
            print("Camera access undetermined, requesting access")
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                print("Camera access granted: \(granted)")
                callback(granted)
            }
        case .denied:
            print("Camera access denied")
            callback(false)
        case .restricted:
            print("Camera access restricted")
            callback(false)
        }
    }
    
    /**
        Sets up the camera and its output to a preview layer
 
        - Parameter videoPreviewLayer: the layer to display the camera preview
    */
    func setupCamera(withVideoPreviewLayer videoPreviewLayer: AVCaptureVideoPreviewLayer) {
        if let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first,
            let deviceInput = try? AVCaptureDeviceInput(device: videoDevice) {
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .vga640x480
            guard self.captureSession.canAddInput(deviceInput) else {
                print("Could not add video device input to the session")
                self.captureSession.commitConfiguration()
                return
            }
            self.captureSession.addInput(deviceInput)
            
            let videoOutput = AVCaptureVideoDataOutput()
            guard self.captureSession.canAddOutput(videoOutput) else {
                print("Could not add video out to the session")
                self.captureSession.commitConfiguration()
                return
            }
            self.captureSession.addOutput(videoOutput)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem))
            // Always process the frames
            let captureConnection = videoOutput.connection(with: .video)
            captureConnection?.isEnabled = true
            self.captureSession.commitConfiguration()
            
            videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer.session = self.captureSession
            
            self.captureSession.startRunning()
        } else {
            print("Could not create video device input")
        }
    }
    
    func stopCaptureSession() {
        if self.captureSession.isRunning {
            self.captureSession.stopRunning()
        }
    }
    
    /**
        Determines the camera's orientation depending on device orientation. Vision algorithms aren't orientation-agnostic,
        so when we make a Vision request, we need to use an orientation that's relative to the camera itself.
 
        - Returns: How the device is currently oriented (portrait, landscape on one of its sides, or portrait upside-down)
    */
    func exifOrientationFromDeviceOrientiation() -> CGImagePropertyOrientation {
        let currentDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation
        
        switch currentDeviceOrientation {
        case .portraitUpsideDown:
            exifOrientation = .left
        case .landscapeLeft:
            exifOrientation = .upMirrored
        case .landscapeRight:
            exifOrientation = .down
        default:
            exifOrientation = .up
        }
        return exifOrientation
    }
    
    /**
        Scan for barcodes with the given image buffer
 
        - Parameter buffer: The image buffer to scan from, typically taken directly from a camera viewport
    */
    func scanBarcode(inBuffer buffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else { return }
        let exifOrientation = self.exifOrientationFromDeviceOrientiation()
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
        do {
            let barcodeRequest = VNDetectBarcodesRequest { (request, error) in
                DispatchQueue.main.async {
                    if let results = request.results as? [VNBarcodeObservation] {
                        self.delegate?.onBarcodeScanned(results)
                    }
                }
            }
            try imageRequestHandler.perform([barcodeRequest])
        } catch {
            print(error)
        }
    }
    
}

extension VisionPresenter : AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        self.scanBarcode(inBuffer: sampleBuffer)
    }
}
