//
//  ViewController.swift
//  MLVision
//
//  Created by Hakeem Hasan on 1/18/19.
//  Copyright © 2019 Nasah Apps, LLC. All rights reserved.
//

import UIKit
import Vision

class ViewController: UIViewController {
    
    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var logTextView: UITextView!
    
    let presenter = VisionPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.presenter.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.presenter.checkCameraPermission { (granted) in
            if granted {
                self.presenter.setupCamera(withVideoPreviewLayer: self.previewView.videoPreviewLayer)
            } else {
                self.showAlert(withMessage: "Camera permission denied, exiting app", exitAppOnClose: true)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.presenter.stopCaptureSession()
    }
    
    func showAlert(withMessage message: String, exitAppOnClose: Bool) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            if exitAppOnClose {
                exit(0)
            }
        }))
        present(alert, animated: true, completion: nil)
    }

}

extension ViewController : VisionPresenterDelegate {
    func onBarcodeScanned(_ barcodes: [VNBarcodeObservation]) {
        var text = ""
        barcodes.sorted(by: { (prev, next) -> Bool in
            let prevConfidence = prev.confidence
            let nextConfidence = next.confidence
            return prevConfidence > nextConfidence
        }).forEach({ (barcode) in
            text += String.init(format: "%.1f: ", barcode.confidence * 100)
            text += "\(barcode.symbology.rawValue) \(barcode.payloadStringValue ?? "nil")\n"
        })
        print(text)
        self.logTextView.text = text
    }
}
