//
//  PreviewView.swift
//  MLVision
//
//  Created by Hakeem Hasan on 1/22/19.
//  Copyright © 2019 Nasah Apps, LLC. All rights reserved.
//

import UIKit
import AVFoundation

class PreviewView: UIView {
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
}
