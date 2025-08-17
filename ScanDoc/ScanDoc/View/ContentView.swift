//
//  ContentView.swift
//  ScanDoc
//
//  Created by Hardik Darji on 12/08/25.
//

import SwiftUI
#Preview {
    ContentView()
}

struct ContentView: View {
    
    @State var scannedImages: [DocImage] = [] //[DocImage(img:UIImage(imageLiteralResourceName: "imgSample")), DocImage(img:UIImage(imageLiteralResourceName: "imgSample"))]
    @State var path = NavigationPath()

    var body: some View {
        
        NavigationStack(path: $path) {
            VStack(spacing: 20) {
                Text("Document Scanner")
                Spacer()
            }
            .navigationTitle("Scan Document")
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if scannedImages.count > 0  {
                        path.append(AppRoute.preview)
                    }
                    else {
                        path.append(AppRoute.scanning)
                    }
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .preview:
                    ImagePreviewView(images: $scannedImages, path: $path)
                case .scanning:
                    ScannerView(scannedImages: $scannedImages, path: $path)
                }
            }
        }
        
    }
}
