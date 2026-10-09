import AVFoundation
import UIKit

/// Wraps an AVCaptureSession that shows a live preview and captures high-quality stills.
final class CameraService: NSObject, ObservableObject {
    enum Status {
        case unknown
        case running
        case denied
        case unavailable
    }

    @Published private(set) var status: Status = .unknown
    @Published private(set) var isCapturing = false

    let session = AVCaptureSession()

    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.ashishsin19.fakecatcha.camera")
    private var isConfigured = false
    private var captureContinuation: CheckedContinuation<UIImage?, Never>?

    @MainActor
    func start() async {
        let granted: Bool
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            granted = true
        case .notDetermined:
            granted = await AVCaptureDevice.requestAccess(for: .video)
        default:
            granted = false
        }
        guard granted else {
            status = .denied
            return
        }
        let ok = await configureAndRun()
        status = ok ? .running : .unavailable
    }

    func stop() {
        sessionQueue.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }

    @MainActor
    func capturePhoto() async -> UIImage? {
        guard status == .running, captureContinuation == nil else { return nil }
        isCapturing = true
        defer { isCapturing = false }
        return await withCheckedContinuation { (continuation: CheckedContinuation<UIImage?, Never>) in
            captureContinuation = continuation
            sessionQueue.async {
                let settings = AVCapturePhotoSettings()
                settings.photoQualityPrioritization = .quality
                self.photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    private func configureAndRun() async -> Bool {
        await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            sessionQueue.async {
                let ok = self.configureIfNeeded()
                if ok, !self.session.isRunning {
                    self.session.startRunning()
                }
                continuation.resume(returning: ok)
            }
        }
    }

    /// Must be called on `sessionQueue`.
    private func configureIfNeeded() -> Bool {
        if isConfigured { return true }
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return false
        }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .photo
        guard session.canAddInput(input), session.canAddOutput(photoOutput) else { return false }
        session.addInput(input)
        session.addOutput(photoOutput)
        photoOutput.maxPhotoQualityPrioritization = .quality

        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()
        } catch {
            // Focus configuration is optional.
        }

        isConfigured = true
        return true
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        let image: UIImage? = (error == nil) ? photo.fileDataRepresentation().flatMap { UIImage(data: $0) } : nil
        DispatchQueue.main.async {
            self.captureContinuation?.resume(returning: image)
            self.captureContinuation = nil
        }
    }
}
