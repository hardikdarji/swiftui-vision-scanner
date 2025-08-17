//
//  Enums.swift
//  ScanDoc
//
//  Created by Hardik Darji on 10/08/25.
//

import SwiftUI

struct DocImage  {
    var img: UIImage
    var brightness: Double = 0
    var contrast: Double = 1
    var rotationAngle: CGFloat = 0
}
// MARK: - Supporting Types and Views
enum FilterType: String, CaseIterable {
    case none = "Original"
    case grayscale = "Grayscale"
    case blackAndWhite = "B&W"
    case rotateLeft = "RotateLeft"
    case rotateRight = "RotateRight"
//    case crop = "Crop"
}

enum AppRoute: Hashable {
    case preview
    case scanning
}

extension CGRect {
    var area: CGFloat {
        return width * height
    }
}
// Use the official Apple sample code
extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up:
            self = .up
        case .upMirrored:
            self = .upMirrored
        case .down:
            self = .down
        case .downMirrored:
            self = .downMirrored
        case .left:
            self = .left
        case .leftMirrored:
            self = .leftMirrored
        case .right:
            self = .right
        case .rightMirrored:
            self = .rightMirrored
        @unknown default:
            fatalError()
        }
    }
}



struct FilterButton: View {
    let filter: FilterType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                
                Text(filter.rawValue)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .primary)
            }
        }
    }
}
#Preview {
    ImageStackButton(img: Image("imgSample"), count: 3, action: {
        
    })
}

struct ImageStackButton: View {
    let img: Image?
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                ZStack(alignment: .topTrailing) {
                    img?
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange, lineWidth: 2)
                        )
                    
                    // Count circle badge
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Text("\(count)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                        .offset(x: -5, y: 5) // Slightly outside the image bounds
                }
            }
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.blue)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}


private func rotateImage(currentImage: UIImage, clockwise: Bool) -> UIImage? {
    let rotationAngle = clockwise ? -CGFloat.pi / 2 : CGFloat.pi / 2
    
    guard let cgImage = currentImage.cgImage else { return nil}
    let ciImage = CIImage(cgImage: cgImage)
    
    // Apply rotation transform
    let transform = CGAffineTransform(rotationAngle: rotationAngle)
    let rotatedCIImage = ciImage.transformed(by: transform)

    return UIImage(ciImage: rotatedCIImage)
}
