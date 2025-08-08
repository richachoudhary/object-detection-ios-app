import Foundation
import CoreML
import Vision
import UIKit

class ObjectDetector: ObservableObject {
    @Published var detectedObjects: [DetectedObject] = []
    @Published var isLoading = false
    
    private var model: VNCoreMLModel?
    
    // 🧪 TEST FLAG: Set to true to use dummy detections instead of real model
    private let USE_DUMMY_DETECTION = true
    
    init() {
        loadModel()
    }
    
    private func loadModel() {
        // Try loading compiled model first
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
        
        // Try loading .mlmodel file
        guard let modelURL = Bundle.main.url(forResource: "YOLOv3", withExtension: "mlmodel") else {
            print("Failed to find YOLOv3.mlmodel in app bundle")
            // Debug: List all bundle resources
            if let bundlePath = Bundle.main.resourcePath {
                print("Bundle resources:")
                try? FileManager.default.contentsOfDirectory(atPath: bundlePath).forEach { print("  \($0)") }
            }
            return
        }
        
        do {
            let mlModel = try MLModel(contentsOf: modelURL)
            
            // Debug model information
            print("🔍 [ObjectDetector] Model description: \(mlModel.modelDescription)")
            print("🔍 [ObjectDetector] Input descriptions:")
            for input in mlModel.modelDescription.inputDescriptionsByName {
                print("  - \(input.key): \(input.value)")
            }
            print("🔍 [ObjectDetector] Output descriptions:")
            for output in mlModel.modelDescription.outputDescriptionsByName {
                print("  - \(output.key): \(output.value)")
            }
            
            model = try VNCoreMLModel(for: mlModel)
            print("Model loaded successfully from .mlmodel file")
        } catch {
            print("Failed to load model: \(error.localizedDescription)")
        }
    }
    
    func detectObjects(in image: UIImage) {
        print("🔍 [ObjectDetector] Starting object detection...")
        print("🔍 [ObjectDetector] Image size: \(image.size)")
        
        // 🧪 TEST MODE: Use dummy detection if flag is enabled
        if USE_DUMMY_DETECTION {
            print("🧪 [ObjectDetector] TEST MODE: Using dummy detection")
            generateDummyDetections(for: image)
            return
        }
        
        guard let model = model else {
            print("❌ [ObjectDetector] Model not loaded")
            return
        }
        print("✅ [ObjectDetector] Model is available")
        
        guard let cgImage = image.cgImage else {
            print("❌ [ObjectDetector] Failed to convert UIImage to CGImage")
            return
        }
        print("✅ [ObjectDetector] CGImage conversion successful")
        print("🔍 [ObjectDetector] CGImage size: \(cgImage.width)x\(cgImage.height)")
        
        isLoading = true
        print("🔄 [ObjectDetector] Setting isLoading = true")
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            print("🔍 [ObjectDetector] VNCoreMLRequest callback called")
            
            DispatchQueue.main.async {
                self?.isLoading = false
                print("🔄 [ObjectDetector] Setting isLoading = false")
                
                if let error = error {
                    print("❌ [ObjectDetector] Detection error: \(error.localizedDescription)")
                    return
                }
                
                print("✅ [ObjectDetector] No errors, processing results...")
                print("🔍 [ObjectDetector] Number of results: \(request.results?.count ?? 0)")
                
                // Debug: Print all result types
                if let results = request.results {
                    for (index, result) in results.enumerated() {
                        print("🔍 [ObjectDetector] Result \(index): \(type(of: result))")
                        if let classificationResult = result as? VNClassificationObservation {
                            print("🔍 [ObjectDetector] Classification: \(classificationResult.identifier) - \(classificationResult.confidence)")
                        }
                        if let objectResult = result as? VNRecognizedObjectObservation {
                            print("🔍 [ObjectDetector] Object: \(objectResult.labels.first?.identifier ?? "unknown") - \(objectResult.labels.first?.confidence ?? 0)")
                        }
                    }
                }
                
                self?.processDetectionResults(request.results)
            }
        }
        
        // YOLOv3 specific configuration
        request.imageCropAndScaleOption = .scaleFill
        print("🔍 [ObjectDetector] Image crop and scale option set to scaleFit")
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        print("🔍 [ObjectDetector] VNImageRequestHandler created")
        
        DispatchQueue.global(qos: .userInitiated).async {
            print("🔍 [ObjectDetector] Starting detection on background queue...")
            do {
                try handler.perform([request])
                print("✅ [ObjectDetector] Handler.perform completed successfully")
            } catch {
                print("❌ [ObjectDetector] Handler.perform failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("🔄 [ObjectDetector] Setting isLoading = false due to error")
                }
            }
        }
    }
    
    private func processDetectionResults(_ results: [VNObservation]?) {
        print("🔍 [ObjectDetector] processDetectionResults called")
        
        guard let results = results as? [VNRecognizedObjectObservation] else {
            print("❌ [ObjectDetector] Results are not VNRecognizedObjectObservation type")
            print("🔍 [ObjectDetector] Actual results type: \(type(of: results))")
            print("🔍 [ObjectDetector] Results count: \(results?.count ?? 0)")
            if let results = results {
                for (index, result) in results.enumerated() {
                    print("🔍 [ObjectDetector] Result \(index): \(type(of: result))")
                }
            }
            detectedObjects = []
            return
        }
        
        print("✅ [ObjectDetector] Results are VNRecognizedObjectObservation")
        print("🔍 [ObjectDetector] Number of VNRecognizedObjectObservation: \(results.count)")
        
        let processedObjects = results.compactMap { observation -> DetectedObject? in
            print("🔍 [ObjectDetector] Processing observation with \(observation.labels.count) labels")
            
            guard let topLabel = observation.labels.first else { 
                print("❌ [ObjectDetector] No labels found in observation")
                return nil 
            }
            
            print("🔍 [ObjectDetector] Top label: \(topLabel.identifier), confidence: \(topLabel.confidence)")
            print("🔍 [ObjectDetector] Bounding box: \(observation.boundingBox)")
            
            return DetectedObject(
                label: topLabel.identifier,
                confidence: topLabel.confidence,
                boundingBox: observation.boundingBox
            )
        }
        
        print("🔍 [ObjectDetector] Processed \(processedObjects.count) objects before filtering")
        
        // First show all objects regardless of confidence
        print("🔍 [ObjectDetector] All detected objects (any confidence):")
        for (index, obj) in processedObjects.enumerated() {
            print("  \(index + 1). \(obj.label) - \(Int(obj.confidence * 100))% at \(obj.boundingBox)")
        }
        
        let filteredObjects = processedObjects.filter { $0.confidence > 0.1 } // Lowered threshold for testing
        print("🔍 [ObjectDetector] Filtered to \(filteredObjects.count) objects with confidence > 0.1")
        
        detectedObjects = filteredObjects
        
        if detectedObjects.isEmpty {
            print("⚠️ [ObjectDetector] No objects detected with sufficient confidence")
        } else {
            print("✅ [ObjectDetector] Final detected objects:")
            for (index, obj) in detectedObjects.enumerated() {
                print("  \(index + 1). \(obj.label) - \(Int(obj.confidence * 100))% at \(obj.boundingBox)")
            }
        }
    }
    
    // 🧪 DUMMY DETECTION FUNCTION FOR TESTING UI
    private func generateDummyDetections(for image: UIImage) {
        print("🧪 [ObjectDetector] Generating dummy detections...")
        
        isLoading = true
        print("🔄 [ObjectDetector] Setting isLoading = true")
        
        // Simulate processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("🧪 [ObjectDetector] Creating dummy objects...")
            
            // Create dummy detections matching the pyramid box stack layout
            let dummyObjects = [
                // Large base box (center-bottom, biggest box)
                DetectedObject(
                    label: "box",
                    confidence: 0.94,
                    boundingBox: CGRect(x: 0.25, y: 0.35, width: 0.5, height: 0.55) // Large central base box
                ),
                
                // Medium box on top of large box
                DetectedObject(
                    label: "package",
                    confidence: 0.89,
                    boundingBox: CGRect(x: 0.35, y: 0.15, width: 0.3, height: 0.35) // Medium box on top
                ),
                
                // Small box on top of the stack
                DetectedObject(
                    label: "box",
                    confidence: 0.86,
                    boundingBox: CGRect(x: 0.42, y: 0.05, width: 0.16, height: 0.2) // Small top box
                ),
                
                // Left side standalone box
                DetectedObject(
                    label: "package",
                    confidence: 0.91,
                    boundingBox: CGRect(x: 0.05, y: 0.45, width: 0.18, height: 0.45) // Left tall box
                ),
                
                // Right side small box
                DetectedObject(
                    label: "box",
                    confidence: 0.83,
                    boundingBox: CGRect(x: 0.78, y: 0.65, width: 0.17, height: 0.25) // Right small box
                )
            ]
            
            print("🧪 [ObjectDetector] Created \(dummyObjects.count) dummy objects:")
            for (index, obj) in dummyObjects.enumerated() {
                print("  \(index + 1). \(obj.label) - \(Int(obj.confidence * 100))% at \(obj.boundingBox)")
            }
            
            self.detectedObjects = dummyObjects
            self.isLoading = false
            
            print("🔄 [ObjectDetector] Setting isLoading = false")
            print("✅ [ObjectDetector] Dummy detection completed!")
        }
    }
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