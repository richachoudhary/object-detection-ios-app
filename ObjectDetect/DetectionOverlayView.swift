import SwiftUI

struct DetectionOverlayView: View {
    let detectedObjects: [DetectedObject]
    let imageSize: CGSize
    
    var body: some View {
        GeometryReader { geometry in
            let _ = print("🎯 [DetectionOverlayView] Rendering with \(detectedObjects.count) objects")
            let _ = print("🎯 [DetectionOverlayView] Geometry size: \(geometry.size)")
            let _ = print("🎯 [DetectionOverlayView] Image size: \(imageSize)")
            
            ForEach(detectedObjects) { object in
                let boundingBox = convertBoundingBox(object.boundingBox, 
                                                   imageSize: imageSize, 
                                                   viewSize: geometry.size)
                let _ = print("🎯 [DetectionOverlayView] Drawing box for \(object.label) at \(boundingBox)")
                
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