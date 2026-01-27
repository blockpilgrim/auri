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
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )

                Button(action: { image = nil }) {
                    Label("Retake Photo", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
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
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button(action: openCamera) {
                    Label("Take Photo", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
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
