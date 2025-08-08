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
    
    // Static reference to allow external access
    static var current: CameraViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        CameraViewController.current = self
        setupCamera()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        CameraViewController.current = nil
        
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(for: .video) else {
            print("Unable to access back camera!")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            photoOutput = AVCapturePhotoOutput()
            
            if captureSession.canAddInput(input) && captureSession.canAddOutput(photoOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(photoOutput)
                
                setupLivePreview()
            }
        } catch {
            print("Error Unable to initialize back camera: \(error.localizedDescription)")
        }
    }
    
    private func setupLivePreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
            
            DispatchQueue.main.async {
                self.previewLayer.frame = self.view.bounds
            }
        }
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("📷 [CameraView] Photo capture finished")
        
        if let error = error {
            print("❌ [CameraView] Photo capture error: \(error.localizedDescription)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else { 
            print("❌ [CameraView] Failed to get image data from photo")
            return 
        }
        print("✅ [CameraView] Got image data, size: \(imageData.count) bytes")
        
        guard let image = UIImage(data: imageData) else { 
            print("❌ [CameraView] Failed to create UIImage from data")
            return 
        }
        print("✅ [CameraView] Created UIImage, size: \(image.size)")
        
        print("📷 [CameraView] Calling onImageCaptured callback")
        onImageCaptured?(image)
        
        print("📷 [CameraView] Starting object detection...")
        objectDetector?.detectObjects(in: image)
    }
} 