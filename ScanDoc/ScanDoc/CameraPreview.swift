//
//  CameraPreview.swift
//  ScanDoc
//
//  Created by Hardik Darji on 10/08/25.
//

import SwiftUI
import AVFoundation

// MARK: - Enhanced Camera Preview with Proper Coordinate System
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    @Binding var previewLayer: AVCaptureVideoPreviewLayer?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill  // This is key!
        view.layer.addSublayer(previewLayer)
        
        // Store reference to preview layer for coordinate conversion
        DispatchQueue.main.async {
            self.previewLayer = previewLayer
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}
