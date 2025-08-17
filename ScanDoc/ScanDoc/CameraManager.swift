//
//  CameraManager.swift
//  ScanDoc
//
//  Created by Hardik Darji on 10/08/25.
//

import SwiftUI
import AVFoundation
import Vision
// MARK: - Camera Manager
class CameraManager: NSObject, ObservableObject {
    @Published var detectedRectangle: VNRectangleObservation?
    @Published var isDocumentStable = false
    @Published var captureCountdown = 0
    @Published var previewLayer: AVCaptureVideoPreviewLayer?

    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    
    private var captureCompletion: ((UIImage) -> Void)?
    private var stabilityFrames = 0
    private let requiredStableFrames = 3
    private var countdownTimer: Timer?
    
    private var lastFrameProcessTime: TimeInterval = 0

    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        captureSession.sessionPreset = .photo
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frame.processing"))
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage) -> Void) {
        captureCompletion = completion
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    func stopSession() {
        captureSession.stopRunning()
    }
    
    var session: AVCaptureSession {
        return captureSession
    }

    private func startAutoCaptureCountdown() {
        print("startAutoCaptureCountdown called")
        captureCountdown = 2
        countdownTimer?.invalidate() // Prevent multiple timers
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.captureCountdown -= 1
            print("self.captureCountdown", self.captureCountdown)
            
            if self.captureCountdown <= 0 {
                timer.invalidate()
            }
        }
    }

    func cancelAutoCapture() {
        countdownTimer?.invalidate()
        DispatchQueue.main.async {
            self.captureCountdown = 0
            self.isDocumentStable = false
        }
    }
}

// MARK: - Camera Delegate Extensions
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
 
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectRectanglesRequest { [weak self] request, error in
            
            guard let observations = request.results as? [VNRectangleObservation], !observations.isEmpty else {
                DispatchQueue.main.async {
                    //self?.detectedRectangle = nil
                    self?.cancelAutoCapture()
                }
                return
            }
            
            // Choose the rectangle with the largest area
            let bestRectangle = observations
                .filter { $0.confidence >= 1.0 && (self?.isValidDocumentSize($0) ?? true) }
                .max(by: { $0.boundingBox.area < $1.boundingBox.area })
            
            if let rectangle = bestRectangle {
                DispatchQueue.main.async {
                    self?.detectedRectangle = rectangle
//                    print("Confidence: \(rectangle.confidence)")
//                    print("Rectangle: \(rectangle.boundingBox)")
                    self?.evaluateStability(rectangle)
                }
            } else {
                DispatchQueue.main.async {
                    self?.detectedRectangle = nil
                    self?.cancelAutoCapture()
                }
            }
        }
        request.minimumAspectRatio = 0.7
        request.maximumAspectRatio = 1.0
        request.quadratureTolerance = 25.0
        request.minimumConfidence = 0.8
        request.maximumObservations = 1

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
    
    private func isValidDocumentSize(_ rectangle: VNRectangleObservation) -> Bool {
        let width = abs(rectangle.topRight.x - rectangle.topLeft.x)
        let height = abs(rectangle.topLeft.y - rectangle.bottomLeft.y)
        let area = width * height
        
        return area > 0.1 // Document should occupy at least 10% of frame
    }
    
    private func evaluateStability(_ rectangle: VNRectangleObservation) {
        // Simple stability check - in production, compare with previous frames
        stabilityFrames += 1
        
        if stabilityFrames >= requiredStableFrames {
            if !isDocumentStable {
                isDocumentStable = true
                startAutoCaptureCountdown()
            }
        }
        
        // Reset stability if no rectangle detected for a while
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.detectedRectangle == nil {
                self.stabilityFrames = 0
                self.cancelAutoCapture()
            }
//        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        
        // Process the captured image
        let processedImage = processImage(image)
        DispatchQueue.main.async {
            self.captureCompletion?(processedImage)
        }
    }
    
    private func processImage(_ image: UIImage) -> UIImage {
        guard let rectangle = detectedRectangle else { return image }
        
        // Crop and enhance the image based on detected rectangle
        let processor = ImageProcessor()
        return processor.processScannedImage(image, rectangle: rectangle) ?? image
    }
}
