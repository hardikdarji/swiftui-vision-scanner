//
//  ScannerView.swift
//  ScanDoc
//
//  Created by Hardik Darji on 12/08/25.
//
import SwiftUI

// MARK: - Document Scanner View
struct ScannerView: View {

    @StateObject private var cameraManager = CameraManager()
    @Binding var scannedImages: [DocImage]
    @Binding var path: NavigationPath
    var body: some View {
        
        ZStack {
            // Camera Preview
            CameraPreview(
                session: cameraManager.session,
                previewLayer: $cameraManager.previewLayer
            )
//            .ignoresSafeArea()
            
            // Document Detection Overlay with preview layer reference
            if let rectangle = cameraManager.detectedRectangle {
                DocumentOverlay(
                    rectangle: rectangle,
                    isStable: cameraManager.isDocumentStable,
                    previewLayer: cameraManager.previewLayer
                )
            }

            // UI Controls
            VStack {
                HStack {
                    if cameraManager.isDocumentStable && cameraManager.captureCountdown > 0
                    {
                        Text("\(cameraManager.captureCountdown)")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.green)
                            .padding()
                    }
                }
                .onChange(of: cameraManager.captureCountdown) { oldValue, newValue in
                    if cameraManager.isDocumentStable && cameraManager.captureCountdown <= 0 {
                        //AUTO CAPTURE AFTER <3> SECONDS OF STABLITY
                        self.cameraManager.capturePhoto { img in
                            scannedImages.append(DocImage(img: img))
                        }
                    }
                }
                
                Spacer()
                
                // Instructions
                VStack {
                    if cameraManager.detectedRectangle == nil {
                        showInstructionView(msg: "Finding Document")
                    } else if cameraManager.isDocumentStable {
                        showInstructionView(msg: "Hold steady - Auto capturing...")
                    } else {
                        showInstructionView(msg: "Hold steady for auto capture")
                    }
                }
                .padding(.bottom, 44)
                
                // Manual Capture Button
                manuallyCaptureButton()
                
                if let docImg = scannedImages.last {
                    HStack {
                        ImageStackButton(img: Image(uiImage: docImg.img), count: self.scannedImages.count, action: {
                            path.removeLast()
                        })
                        .id("imageButton") // Important for positioning

                        Spacer()
                    }
                    .padding()
                }
                
            }
        }
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        
    }
    
    func manuallyCaptureButton() -> some View {
        HStack {
            Spacer()
            
            //MANUALLY TAP ON CAPTURE
            Button(action: {
                self.cameraManager.capturePhoto { img in
                    self.scannedImages.append(DocImage(img: img))
                }
            }) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(Color.gray, lineWidth: 2)
                            .frame(width: 60, height: 60)
                    )
            }
            
            Spacer()
        }
    }
    
    func showInstructionView(msg: String) -> some View {
        Text(msg)
            .foregroundColor(.white)
            .padding(.horizontal)
            .padding(4)
            .background(Color.black.opacity(0.7))
            .cornerRadius(4)
    }
}
