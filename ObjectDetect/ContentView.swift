//
//  ContentView.swift
//  ObjectDetect
//
//  Created by Aayush Chaturvedi on 08/08/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var objectDetector = ObjectDetector()
    @State private var capturedImage: UIImage?
    @State private var showingCamera = false
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title
                Text("Object Detection")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                // Main content area
                if let image = capturedImage {
                    // Display captured image with detection overlay
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 400)
                            .onAppear {
                                print("🖼️ [ContentView] Image appeared in UI")
                                print("🖼️ [ContentView] Image size: \(image.size)")
                            }
                        
                        DetectionOverlayView(
                            detectedObjects: objectDetector.detectedObjects,
                            imageSize: image.size
                        )
                        .onAppear {
                            print("🎯 [ContentView] DetectionOverlayView appeared")
                            print("🎯 [ContentView] Number of detected objects: \(objectDetector.detectedObjects.count)")
                        }
                        .onChange(of: objectDetector.detectedObjects) { objects in
                            print("🎯 [ContentView] Detected objects changed!")
                            print("🎯 [ContentView] New count: \(objects.count)")
                            for (index, obj) in objects.enumerated() {
                                print("  \(index + 1). \(obj.label) - \(Int(obj.confidence * 100))%")
                            }
                        }
                    }
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Detection results list
                    if !objectDetector.detectedObjects.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Detected Objects:")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 4) {
                                    ForEach(objectDetector.detectedObjects) { object in
                                        HStack {
                                            Text(object.label.capitalized)
                                                .font(.body)
                                                .fontWeight(.medium)
                                            
                                            Spacer()
                                            
                                            Text("\(Int(object.confidence * 100))%")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 2)
                                                .background(Color.blue.opacity(0.2))
                                                .cornerRadius(8)
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                            .frame(maxHeight: 150)
                        }
                    }
                } else {
                    // Placeholder when no image is captured
                    VStack(spacing: 20) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        Text("Capture or select an image to detect objects")
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 300)
                }
                
                Spacer()
                
                // Loading indicator
                if objectDetector.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Detecting objects...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                // Action buttons
                HStack(spacing: 20) {
                    Button(action: {
                        showingCamera = true
                    }) {
                        HStack {
                            Image(systemName: "camera")
                            Text("Camera")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Gallery")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraViewWrapper(
                objectDetector: objectDetector,
                capturedImage: $capturedImage,
                isPresented: $showingCamera
            )
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $capturedImage, objectDetector: objectDetector)
        }
    }
}

struct CameraViewWrapper: View {
    @ObservedObject var objectDetector: ObjectDetector
    @Binding var capturedImage: UIImage?
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            CameraView(objectDetector: objectDetector, capturedImage: $capturedImage)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Spacer()
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                    .padding()
                }
                
                Spacer()
                
                Button(action: {
                    // Trigger photo capture
                    CameraViewController.current?.capturePhoto()
                }) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: 2)
                                .frame(width: 60, height: 60)
                        )
                }
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    ContentView()
}
