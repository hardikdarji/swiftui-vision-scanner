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
                
                Button {
                    //Action
                    path.append(AppRoute.scanning)

                } label: {
                    Text("Scan Document")
                        .padding(12)
                        .border(Color.blue, width: 1)
                }
                
                if scannedImages.count > 0  {
                    Button {
                        //Action
                        path.append(AppRoute.preview)

                    } label: {
                        Text("Preview Document")
                            .padding(12)
                            .border(Color.blue, width: 1)
                    }
                }

                
            }
            .navigationTitle("Scan Document")
            .toolbarTitleDisplayMode(.inline)
            
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
