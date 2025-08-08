# Building a Real-Time Object Detection App with SwiftUI, CoreML, and Vision

Object detection on mobile devices has come a long way. What used to require server-side processing and expensive hardware can now run smoothly on your iPhone, detecting everything from everyday objects to specific items in real-time. With Apple's CoreML and Vision frameworks, building an object detection app is more accessible than ever.

Today, we'll build a complete object detection app using SwiftUI that can both capture photos with the camera and select images from the photo library. The app will identify objects, draw bounding boxes around them, and show confidence scores—all running locally on the device.

## What We're Building

Our app will have these key features:
- Real-time camera capture for object detection
- Photo library integration for analyzing existing images
- Live bounding box overlays with object labels
- Confidence score filtering
- Clean SwiftUI interface

Here's our project structure:

```
ObjectDetect/
├── ObjectDetectApp.swift          # App entry point
├── ContentView.swift              # Main UI and navigation
├── ObjectDetector.swift           # CoreML and Vision logic
├── CameraView.swift               # Camera capture handling
├── ImagePicker.swift              # Photo library integration
├── DetectionOverlayView.swift     # Bounding box rendering
└── YOLOv3.mlmodel                # Our object detection model
```

## Setting Up the Project

Start by creating a new SwiftUI project in Xcode. We'll need to add a few capabilities:

1. **Camera Usage**: Add `NSCameraUsageDescription` to your Info.plist
2. **Photo Library**: Add `NSPhotoLibraryUsageDescription` to your Info.plist

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to capture photos for object detection.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select images for object detection.</string>
```

## The Core: ObjectDetector Class

The heart of our app is the `ObjectDetector` class, which handles all the machine learning magic:

```swift
import Foundation
import CoreML
import Vision
import UIKit

class ObjectDetector: ObservableObject {
    @Published var detectedObjects: [DetectedObject] = []
    @Published var isLoading = false
    
    private var model: VNCoreMLModel?
    
    init() {
        loadModel()
    }
    
    private func loadModel() {
        // Try loading compiled model first (.mlmodelc)
        if let compiledModelURL = Bundle.main.url(forResource: "YOLOv3", withExtension: "mlmodelc") {
            do {
                let mlModel = try MLModel(contentsOf: compiledModelURL)
                model = try VNCoreMLModel(for: mlModel)
                print("Model loaded successfully from compiled version")
                return
            } catch {
                print("Failed to load compiled model: \(error.localizedDescription)")
            }
        }
        
        // Fallback to .mlmodel file
        guard let modelURL = Bundle.main.url(forResource: "YOLOv3", withExtension: "mlmodel") else {
            print("Failed to find YOLOv3.mlmodel in app bundle")
            return
        }
        
        do {
            let mlModel = try MLModel(contentsOf: modelURL)
            model = try VNCoreMLModel(for: mlModel)
            print("Model loaded successfully from .mlmodel file")
        } catch {
            print("Failed to load model: \(error.localizedDescription)")
        }
    }
}
```

## Using Core ML with Vision

The Vision framework makes it incredibly easy to use CoreML models for computer vision tasks. Here's how we perform object detection:

```swift
func detectObjects(in image: UIImage) {
    guard let model = model else {
        print("Model not loaded")
        return
    }
    
    guard let cgImage = image.cgImage else {
        print("Failed to convert UIImage to CGImage")
        return
    }
    
    isLoading = true
    
    let request = VNCoreMLRequest(model: model) { [weak self] request, error in
        DispatchQueue.main.async {
            self?.isLoading = false
            
            if let error = error {
                print("Detection error: \(error.localizedDescription)")
                return
            }
            
            self?.processDetectionResults(request.results)
        }
    }
    
    request.imageCropAndScaleOption = .scaleFill
    
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    
    DispatchQueue.global(qos: .userInitiated).async {
        do {
            try handler.perform([request])
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                print("Failed to perform detection: \(error.localizedDescription)")
            }
        }
    }
}
```

The key points here:
- We create a `VNCoreMLRequest` with our loaded model
- Vision handles all the preprocessing (resizing, color space conversion, etc.)
- We process the request on a background queue to keep the UI responsive
- Results are processed back on the main queue for UI updates

## Processing Detection Results

Once Vision returns results, we need to filter and convert them into our app's data structure:

```swift
private func processDetectionResults(_ results: [VNObservation]?) {
    guard let results = results as? [VNRecognizedObjectObservation] else {
        detectedObjects = []
        return
    }
    
    let processedObjects = results.compactMap { observation -> DetectedObject? in
        guard let topLabel = observation.labels.first else { 
            return nil 
        }
        
        return DetectedObject(
            label: topLabel.identifier,
            confidence: topLabel.confidence,
            boundingBox: observation.boundingBox
        )
    }
    
    // Filter out low confidence detections
    let filteredObjects = processedObjects.filter { $0.confidence > 0.3 }
    detectedObjects = filteredObjects
}

struct DetectedObject: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let confidence: Float
    let boundingBox: CGRect
    
    static func == (lhs: DetectedObject, rhs: DetectedObject) -> Bool {
        return lhs.id == rhs.id
    }
}
```

The confidence threshold of 0.3 (30%) helps filter out uncertain detections. You can adjust this based on your needs—higher values give fewer but more confident results.

## Camera Integration

For real-time camera capture, we use AVFoundation wrapped in a UIViewControllerRepresentable:

```swift
import SwiftUI
import AVFoundation
import UIKit

struct CameraView: UIViewControllerRepresentable {
    @ObservedObject var objectDetector: ObjectDetector
    @Binding var capturedImage: UIImage?
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.objectDetector = objectDetector
        controller.onImageCaptured = { image in
            capturedImage = image
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // No updates needed
    }
}

class CameraViewController: UIViewController {
    var objectDetector: ObjectDetector?
    var onImageCaptured: ((UIImage) -> Void)?
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var photoOutput: AVCapturePhotoOutput!
    
    // Camera setup and photo capture implementation...
}
```

*[Placeholder for camera setup code and photo capture delegate methods]*

## Photo Library Integration

For selecting existing photos, we create a simple image picker:

```swift
import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @ObservedObject var objectDetector: ObjectDetector
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let selectedImage = info[.originalImage] as? UIImage {
                parent.image = selectedImage
                parent.objectDetector.detectObjects(in: selectedImage)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
```

## Overlaying Detection Results

The trickiest part is drawing bounding boxes that align correctly with the displayed image. Here's our overlay view:

```swift
import SwiftUI

struct DetectionOverlayView: View {
    let detectedObjects: [DetectedObject]
    let imageSize: CGSize
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(detectedObjects) { object in
                let boundingBox = convertBoundingBox(
                    object.boundingBox, 
                    imageSize: imageSize, 
                    viewSize: geometry.size
                )
                
                Rectangle()
                    .stroke(Color.red, lineWidth: 2)
                    .background(Color.clear)
                    .frame(width: boundingBox.width, height: boundingBox.height)
                    .position(x: boundingBox.midX, y: boundingBox.midY)
                    .overlay(
                        Text("\(object.label) (\(Int(object.confidence * 100))%)")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.red)
                            .cornerRadius(4)
                            .position(x: boundingBox.midX, y: boundingBox.minY - 10),
                        alignment: .topLeading
                    )
            }
        }
    }
    
    private func convertBoundingBox(_ boundingBox: CGRect, imageSize: CGSize, viewSize: CGSize) -> CGRect {
        // Vision framework uses normalized coordinates (0-1) with origin at bottom-left
        // SwiftUI uses top-left origin, so we need to convert
        
        let scaleX = viewSize.width / imageSize.width
        let scaleY = viewSize.height / imageSize.height
        let scale = min(scaleX, scaleY)
        
        let scaledImageSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let offsetX = (viewSize.width - scaledImageSize.width) / 2
        let offsetY = (viewSize.height - scaledImageSize.height) / 2
        
        // Convert from Vision coordinates to SwiftUI coordinates
        let x = boundingBox.minX * scaledImageSize.width + offsetX
        let y = (1 - boundingBox.maxY) * scaledImageSize.height + offsetY
        let width = boundingBox.width * scaledImageSize.width
        let height = boundingBox.height * scaledImageSize.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
```

The coordinate conversion is crucial because:
- Vision framework returns normalized coordinates (0.0 to 1.0)
- Vision uses bottom-left origin, SwiftUI uses top-left
- We need to account for image scaling and positioning within the view

## Putting It All Together: ContentView

Our main view coordinates everything:

```swift
struct ContentView: View {
    @StateObject private var objectDetector = ObjectDetector()
    @State private var capturedImage: UIImage?
    @State private var showingCamera = false
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Object Detection")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                // Main content area
                if let image = capturedImage {
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 400)
                        
                        DetectionOverlayView(
                            detectedObjects: objectDetector.detectedObjects,
                            imageSize: image.size
                        )
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
                    // Placeholder content
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
```

*[Placeholder for example screenshots showing the app in action]*

## Customizing the Model

Want to use a different object detection model? It's straightforward:

1. **Replace the model file**: Simply drag a new `.mlmodel` file into your project
2. **Update the filename**: Change "YOLOv3" to your model's name in the `loadModel()` function
3. **Adjust confidence threshold**: Modify the filter in `processDetectionResults()`

```swift
// Adjust confidence threshold based on your model's performance
let filteredObjects = processedObjects.filter { $0.confidence > 0.5 } // Stricter filtering
```

Popular CoreML object detection models include:
- **YOLOv3/YOLOv4**: Great general-purpose detection
- **MobileNet-SSD**: Lighter weight, good for real-time use
- **Custom models**: Train your own with CreateML or convert from other frameworks

## Troubleshooting

**Model not loading?**
- Ensure the `.mlmodel` file is added to your target
- Check the filename matches exactly (case-sensitive)
- Verify iOS version compatibility

**Bounding boxes misaligned?**
- Double-check coordinate conversion in `DetectionOverlayView`
- Ensure image aspect ratio is preserved
- Test with images of different orientations

**Poor detection performance?**
- Try different confidence thresholds
- Ensure good lighting for camera captures
- Consider image quality and resolution

**App crashes on device?**
- Check memory usage with large models
- Verify all required frameworks are linked
- Test with different device generations

## Performance Tips

1. **Model size matters**: Larger models are more accurate but slower
2. **Image resolution**: Downscale very large images before processing
3. **Threading**: Always run detection on background queues
4. **Memory management**: Consider releasing model resources when not needed

## What's Next?

This foundation opens up many possibilities:

- **Video detection**: Process camera frames in real-time
- **Custom models**: Train models for specific use cases
- **ARKit integration**: Overlay 3D objects on detected items
- **Cloud models**: Combine on-device and server-side detection
- **Multiple models**: Chain different models together

The beauty of CoreML is its flexibility. You can swap models without changing your app's architecture, experiment with different approaches, and even download models dynamically.

Object detection on iOS has never been more accessible. With just a few hundred lines of Swift, you can build powerful computer vision features that run entirely on-device, protecting user privacy while delivering instant results.

*[Placeholder for final app demo images]*

Happy coding! 🚀

---

*Want to see more iOS machine learning tutorials? Follow me for updates on SwiftUI, CoreML, and mobile AI development.*