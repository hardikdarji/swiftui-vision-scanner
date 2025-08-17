//
//  DocumentOverlay.swift
//  ScanDoc
//
//  Created by Hardik Darji on 10/08/25.
//

import Vision
import SwiftUI
import AVFoundation
// MARK: - Correct Document Overlay Implementation
struct DocumentOverlay: View {
    let rectangle: VNRectangleObservation
    let isStable: Bool
    let previewLayer: AVCaptureVideoPreviewLayer?
    
    var body: some View {
        GeometryReader { geometry in
            let points = calculateCorrectPoints(
                rectangle: rectangle,
                containerSize: geometry.size,
                previewLayer: previewLayer
            )
            
            Path { path in
                path.move(to: points[0])
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
                path.closeSubpath()
            }
            .stroke(isStable ? Color.green : Color.clear, lineWidth: 3)
            
            // Corner indicators with labels for debugging
            ForEach(0..<4, id: \.self) { index in
                ZStack {
                    Circle()
                        .fill(isStable ? Color.green : Color.blue)
                        .frame(width: 18, height: 18)
                    
                    // Debug labels
                    Text(getCornerLabel(index))
                        .font(.caption2)
                        .bold()
                        .foregroundColor(.white)
                        .offset(x: 15, y: -15)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.black.opacity(0.7))
                                .frame(width: 20, height: 16)
                        )
                }
                .position(points[index])
            }
            
            // Debug info
            VStack {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Confidence: \(String(format: "%.1f%%", rectangle.confidence * 100))")
                        Text("TL: (\(String(format: "%.3f", rectangle.topLeft.x)), \(String(format: "%.3f", rectangle.topLeft.y)))")

                        Text("Container: \(Int(geometry.size.width))×\(Int(geometry.size.height))")
                        Text("Vision: (\(rectangle.topLeft.x), \(rectangle.topLeft.y))")
                        Text("Mapped: (\(points[0].x), \(points[0].y))")

                    }
                    .font(.caption2)
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                    .padding(8)
                }
                Spacer()
            }
            .padding()
        }
    }
    
}

//MARK: Other moethods
extension DocumentOverlay {
    
    private func calculateCorrectPoints(
        rectangle: VNRectangleObservation,
        containerSize: CGSize,
        previewLayer: AVCaptureVideoPreviewLayer?
    ) -> [CGPoint] {
        
        // Method 1: Use AVCaptureVideoPreviewLayer for accurate conversion (Recommended)
        if let previewLayer = previewLayer {
            return convertUsingPreviewLayer(rectangle: rectangle, previewLayer: previewLayer, containerSize: containerSize)
        }
        
        // Method 2: Manual calculation (Fallback)
        return convertManually(rectangle: rectangle, containerSize: containerSize)
    }
    
    private func convertUsingPreviewLayer(
        rectangle: VNRectangleObservation,
        previewLayer: AVCaptureVideoPreviewLayer,
        containerSize: CGSize
    ) -> [CGPoint] {
        
        let corners = [
            rectangle.topLeft,
            rectangle.topRight,
            rectangle.bottomRight,
            rectangle.bottomLeft
        ]
        
        return corners.map { visionPoint in
            // Convert Vision coordinate (0-1, bottom-left origin) to AVFoundation coordinate
            let avPoint = CGPoint(x: visionPoint.x, y: 1 - visionPoint.y)
            
            // Convert to layer coordinate
            let layerPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: avPoint)
            
            return layerPoint
        }
    }
    
    private func convertManually(rectangle: VNRectangleObservation, containerSize: CGSize) -> [CGPoint] {
        // This is the fallback method - assumes camera fills entire container
        return [
            CGPoint(x: rectangle.topLeft.x * containerSize.width,
                   y: (1 - rectangle.topLeft.y) * containerSize.height),
            CGPoint(x: rectangle.topRight.x * containerSize.width,
                   y: (1 - rectangle.topRight.y) * containerSize.height),
            CGPoint(x: rectangle.bottomRight.x * containerSize.width,
                   y: (1 - rectangle.bottomRight.y) * containerSize.height),
            CGPoint(x: rectangle.bottomLeft.x * containerSize.width,
                   y: (1 - rectangle.bottomLeft.y) * containerSize.height)
        ]
    }
    
    private func getCornerLabel(_ index: Int) -> String {
        switch index {
        case 0: return "TL"
        case 1: return "TR"
        case 2: return "BR"
        case 3: return "BL"
        default: return ""
        }
    }
}
