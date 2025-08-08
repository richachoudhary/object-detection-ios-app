# iOS Object Detection App

A SwiftUI-based iOS application that performs real-time object detection using Core ML and the Vision framework.

## Features

- **Real-time Camera Capture**: Take photos using the device camera
- **Photo Library Integration**: Select images from your photo library
- **Object Detection**: Uses a YOLOv3 Tiny Core ML model to detect objects in images
- **Visual Overlay**: Displays bounding boxes and confidence scores over detected objects
- **Modern UI**: Clean SwiftUI interface with intuitive controls

## Requirements

- iOS 14.0+
- Xcode 12.0+
- Device with camera (for camera functionality)

## Setup Instructions

1. **Open the Project**
   - Open `ObjectDetect.xcodeproj` in Xcode

2. **Verify Model File**
   - Ensure `YOLOv3.mlmodel` is present in the ObjectDetect folder
   - The model should automatically be included in the app bundle

3. **Configure Permissions**
   - The app includes necessary privacy permissions in `Info.plist`:
     - Camera usage description
     - Photo library usage description

4. **Build and Run**
   - Select your target device or simulator
   - Build and run the project (⌘+R)

## How to Use

1. **Launch the App**
   - The main screen shows two options: Camera and Gallery

2. **Take a Photo**
   - Tap "Camera" to open the camera interface
   - Tap the white circle button to capture a photo
   - Tap "Done" to return to the main screen

3. **Select from Gallery**
   - Tap "Gallery" to browse your photo library
   - Select an image for object detection

4. **View Results**
   - Detected objects are highlighted with red bounding boxes
   - Object labels and confidence percentages are displayed
   - A list of detected objects appears below the image

## Technical Details

### Core ML Model
- **Model**: YOLOv3 Tiny (291KB)
- **Format**: .mlmodel (Core ML format)
- **Framework**: Vision + Core ML
- **Confidence Threshold**: 30% (configurable in `ObjectDetector.swift`)

### Architecture
- **ObjectDetector**: Core ML model loading and inference
- **CameraView**: Camera capture functionality
- **DetectionOverlayView**: Visual overlay for detection results
- **ImagePicker**: Photo library integration
- **ContentView**: Main user interface

### Key Files
```
ObjectDetect/
├── ObjectDetector.swift      # Core ML model handling
├── CameraView.swift         # Camera integration
├── DetectionOverlayView.swift # Visual overlays
├── ImagePicker.swift        # Photo library picker
├── ContentView.swift        # Main UI
├── YOLOv3.mlmodel          # Pre-trained model
└── Info.plist              # Privacy permissions
```

## Customization

### Changing the Model
1. Replace `YOLOv3.mlmodel` with your own Core ML model
2. Update the model name in `ObjectDetector.swift`:
   ```swift
   guard let modelURL = Bundle.main.url(forResource: "YourModelName", withExtension: "mlmodel")
   ```

### Adjusting Confidence Threshold
In `ObjectDetector.swift`, modify the filter condition:
```swift
.filter { $0.confidence > 0.3 } // Change 0.3 to your desired threshold
```

### UI Customization
- Modify colors, fonts, and layout in `ContentView.swift`
- Adjust bounding box appearance in `DetectionOverlayView.swift`

## Troubleshooting

1. **Model Not Found Error**
   - Ensure `YOLOv3.mlmodel` is added to the Xcode project
   - Check that the model name matches exactly in the code

2. **Camera Permission Denied**
   - Check device Settings > Privacy & Security > Camera
   - Ensure the app has camera permission

3. **Photo Library Permission Denied**
   - Check device Settings > Privacy & Security > Photos
   - Ensure the app has photo library access

4. **Poor Detection Results**
   - Try images with better lighting
   - Ensure objects are clearly visible
   - Consider adjusting the confidence threshold

## License

This project is for educational purposes. The YOLOv3 model may have its own licensing terms. 