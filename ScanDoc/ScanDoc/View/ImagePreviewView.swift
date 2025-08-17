//
//  ImagePreviewView.swift
//  ScanDoc
//
//  Created by Hardik Darji on 17/08/25.
//

import AVFoundation
import SwiftUI
import Vision
#Preview {
    ContentView()
}

struct ImagePreviewView: View {
    @Binding var images: [DocImage]
    @Binding var path: NavigationPath
    @State private var selectedTabIndex: Int = 0
    @StateObject private var pdfManager = PDFManager()
    
    var body: some View {
        VStack {
            if pdfManager.isLoading {
                ProgressView("Creating PDF...")
                    .padding()
            }
            else {
                VStack {
                    // Image Preview
                    TabView(selection: $selectedTabIndex) {
                        ForEach(images.indices, id: \.self) { index in
                            Image(uiImage: images[selectedTabIndex].img)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: UIScreen.main.bounds.height * 0.85)
                                .padding()
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    VStack(spacing: 20) {
                        Text("Page \(selectedTabIndex + 1) of \(images.count)")
                    }
                    Spacer()
                }
            }
        }
        .navigationTitle("Preview Document")
        .toolbar {
            Button(action: {
                
                self.generateAndOpenPDF()
            }) {
                Text("Share") //
            }
        }
        .navigationBarTitleDisplayMode(.inline)

        
    }
    
}

extension ImagePreviewView {
    private func generateAndOpenPDF() {
        pdfManager.createPDF(from: images.map { $0.img })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let pdfURL = pdfManager.savePDF() {
                // Use share sheet instead of direct opening
                self.showShareSheet(for: pdfURL)
            }
        }
    }

    private func showShareSheet(for url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}
