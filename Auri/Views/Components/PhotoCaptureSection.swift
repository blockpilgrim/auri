import AVFoundation
import SwiftUI
import UIKit

struct PhotoCaptureSection: View {
    @Binding var image: UIImage?
    @Binding var showCamera: Bool
    @State private var cameraUnavailable = false

    var body: some View {
        VStack(spacing: 16) {
            if let capturedImage = image {
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: GlassStyle.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: GlassStyle.cornerRadius)
                            .strokeBorder(GlassStyle.borderGradient, lineWidth: GlassStyle.borderWidth)
                    )

                Button(action: { image = nil }) {
                    Label("Retake Photo", systemImage: "arrow.counterclockwise")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .glassCapsule()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)

                    Text("Capture a photo of your meal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .glassCard()

                Button(action: openCamera) {
                    Label("Take Photo", systemImage: "camera")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .glassCard()
            }
        }
        .padding(.horizontal)
        .alert("Camera Unavailable", isPresented: $cameraUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please enable camera access in Settings to take meal photos.")
        }
    }

    private func openCamera() {
        Task {
            let authorized = await requestCameraPermission()
            await MainActor.run {
                if authorized {
                    showCamera = true
                } else {
                    cameraUnavailable = true
                }
            }
        }
    }

    private func requestCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }
}

#Preview {
    PhotoCaptureSection(image: .constant(nil), showCamera: .constant(false))
}
