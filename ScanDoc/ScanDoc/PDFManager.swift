//
//  PDFKitView.swift
//  ScanDoc
//
//  Created by Hardik Darji on 17/08/25.
//


import SwiftUI
import PDFKit
import UIKit

// MARK: - PDF Generation Function
func createPDFFromImages(_ images: [UIImage]) -> PDFDocument? {
    guard !images.isEmpty else { return nil }
    
    let pdfDocument = PDFDocument()
    
    for (index, image) in images.enumerated() {
        if let pdfPage = createPDFPage(from: image) {
            pdfDocument.insert(pdfPage, at: index)
        }
    }
    
    return pdfDocument
}

// MARK: - Helper Function to Create PDF Page from UIImage
private func createPDFPage(from image: UIImage) -> PDFPage? {
    let pdfData = createPDFData(from: image)
    
    if let data = pdfData,
       let pdfDocument = PDFDocument(data: data),
       let page = pdfDocument.page(at: 0) {
        return page
    }
    
    return nil
}

// MARK: - Create PDF Data from UIImage
private func createPDFData(from image: UIImage) -> Data? {
    let pdfData = NSMutableData()
    
    // Define PDF page size (A4 size in points)
    let pageSize = CGSize(width: 595.2, height: 841.8) // A4 size
    
    // Calculate image size to fit within page while maintaining aspect ratio
    let imageSize = calculateFittedSize(for: image.size, in: pageSize)
    
    // Calculate position to center the image
    let x = (pageSize.width - imageSize.width) / 2
    let y = (pageSize.height - imageSize.height) / 2
    let imageRect = CGRect(x: x, y: y, width: imageSize.width, height: imageSize.height)
    
    // Create PDF context
    UIGraphicsBeginPDFContextToData(pdfData, CGRect(origin: .zero, size: pageSize), nil)
    UIGraphicsBeginPDFPage()
    
    // Draw image in PDF context
    image.draw(in: imageRect)
    
    UIGraphicsEndPDFContext()
    
    return pdfData as Data
}

// MARK: - Calculate Fitted Size
private func calculateFittedSize(for imageSize: CGSize, in pageSize: CGSize) -> CGSize {
    let padding: CGFloat = 40 // 20pt padding on each side
    let availableSize = CGSize(width: pageSize.width - padding, height: pageSize.height - padding)
    
    let widthRatio = availableSize.width / imageSize.width
    let heightRatio = availableSize.height / imageSize.height
    let scaleFactor = min(widthRatio, heightRatio)
    
    return CGSize(width: imageSize.width * scaleFactor, height: imageSize.height * scaleFactor)
}


// MARK: - PDF Manager ObservableObject
class PDFManager: ObservableObject {
    @Published var pdfDocument: PDFDocument?
    @Published var isLoading = false
    
    func createPDF(from images: [UIImage]) {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let pdf = createPDFFromImages(images)
            
            DispatchQueue.main.async {
                self.pdfDocument = pdf
                self.isLoading = false
            }
        }
    }
    
    func savePDF(filename: String = "document.pdf") -> URL? {
        guard let pdfDocument = pdfDocument,
              let data = pdfDocument.dataRepresentation() else {
            return nil
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                   in: .userDomainMask).first!
        let pdfURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try data.write(to: pdfURL)
            return pdfURL
        } catch {
            print("Error saving PDF: \(error)")
            return nil
        }
    }
}

