//
//  ImageProcessor.swift
//  ScanDoc
//
//  Created by Hardik Darji on 10/08/25.
//
import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import AVFoundation
import Vision


// MARK: - Image Processor
class ImageProcessor {
    func processScannedImage(_ image: UIImage, rectangle: VNRectangleObservation) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        // Apply perspective correction
        let correctedImage = correctPerspective(ciImage, rectangle: rectangle)
        
        // Enhance the document
        let enhancedImage = enhanceDocument(correctedImage)
        
        // Convert back to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(enhancedImage, from: enhancedImage.extent) else {
            return nil
        }
        
        // Create UIImage with right rotation (90 degrees clockwise)
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: .right)
    }
    
    private func correctPerspective(_ image: CIImage, rectangle: VNRectangleObservation) -> CIImage {
        let imageSize = image.extent.size
        
        let topLeft = CGPoint(x: rectangle.topLeft.x * imageSize.width,
                             y: rectangle.topLeft.y * imageSize.height)
        let topRight = CGPoint(x: rectangle.topRight.x * imageSize.width,
                              y: rectangle.topRight.y * imageSize.height)
        let bottomLeft = CGPoint(x: rectangle.bottomLeft.x * imageSize.width,
                                y: rectangle.bottomLeft.y * imageSize.height)
        let bottomRight = CGPoint(x: rectangle.bottomRight.x * imageSize.width,
                                 y: rectangle.bottomRight.y * imageSize.height)
        
        let perspectiveFilter = CIFilter.perspectiveCorrection()
        perspectiveFilter.inputImage = image
        perspectiveFilter.topLeft = topLeft
        perspectiveFilter.topRight = topRight
        perspectiveFilter.bottomLeft = bottomLeft
        perspectiveFilter.bottomRight = bottomRight
        
        return perspectiveFilter.outputImage ?? image
    }
    
    private func enhanceDocument(_ image: CIImage) -> CIImage {
        // Apply basic document enhancement
        let contrastFilter = CIFilter.colorControls()
        contrastFilter.inputImage = image
        contrastFilter.contrast = 1.2
        contrastFilter.brightness = 0.1
        
        let sharpenFilter = CIFilter.sharpenLuminance()
        sharpenFilter.inputImage = contrastFilter.outputImage
        sharpenFilter.sharpness = 0.4
        
        return sharpenFilter.outputImage ?? image
    }
}
