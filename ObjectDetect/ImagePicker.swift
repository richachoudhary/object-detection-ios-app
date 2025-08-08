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
            print("📸 [ImagePicker] Image picker finished with selection")
            
            if let selectedImage = info[.originalImage] as? UIImage {
                print("✅ [ImagePicker] Successfully got UIImage from picker")
                print("📸 [ImagePicker] Image size: \(selectedImage.size)")
                
                parent.image = selectedImage
                print("📸 [ImagePicker] Set parent.image")
                
                print("📸 [ImagePicker] Starting object detection...")
                parent.objectDetector.detectObjects(in: selectedImage)
            } else {
                print("❌ [ImagePicker] Failed to get UIImage from picker")
            }
            
            parent.presentationMode.wrappedValue.dismiss()
            print("📸 [ImagePicker] Dismissed image picker")
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
} 