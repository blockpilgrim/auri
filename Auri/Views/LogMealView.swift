import SwiftUI
import UIKit

struct LogMealView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.mealService) private var mealService
    @Environment(\.adherenceEngine) private var adherenceEngine

    @State private var capturedImage: UIImage?
    @State private var mealDescription: String = ""
    @State private var showCamera = false
    @State private var entryMode: EntryMode = .photo
    @State private var isSaving = false

    enum EntryMode: String, CaseIterable {
        case photo = "Photo"
        case text = "Text"
    }

    private var canSave: Bool {
        switch entryMode {
        case .photo:
            return capturedImage != nil
        case .text:
            return !mealDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Custom glass segmented toggle
                HStack(spacing: 0) {
                    ForEach(EntryMode.allCases, id: \.self) { mode in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                entryMode = mode
                            }
                        } label: {
                            Text(mode.rawValue)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(entryMode == mode ? .white.opacity(0.9) : .white.opacity(0.4))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    entryMode == mode
                                        ? Capsule().fill(.white.opacity(0.12))
                                        : Capsule().fill(Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .glassCapsule()
                .padding(.horizontal)

                if entryMode == .photo {
                    PhotoCaptureSection(image: $capturedImage, showCamera: $showCamera)
                } else {
                    TextEntrySection(description: $mealDescription)
                }

                Spacer()

                TrackingButtons(isEnabled: canSave && !isSaving, onSave: saveMeal)
                    .padding(.bottom)
            }
            .padding(.top)
            .background(Color.black)
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(image: $capturedImage)
                    .ignoresSafeArea()
            }
        }
        .preferredColorScheme(.dark)
    }

    private func saveMeal(isOnTrack: Bool) {
        guard let mealService, let adherenceEngine else { return }

        isSaving = true

        let mealId = UUID()
        var photoPath: String? = nil

        if let image = capturedImage {
            photoPath = try? mealService.savePhoto(image, for: mealId)
        }

        let trimmedDescription = mealDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        let meal = Meal(
            id: mealId,
            timestamp: Date(),
            photoPath: photoPath,
            mealDescription: trimmedDescription.isEmpty ? nil : trimmedDescription,
            isOnTrack: isOnTrack,
            source: entryMode == .photo ? .photo : .text
        )

        do {
            try mealService.saveMeal(meal)
            adherenceEngine.recalculate()
            adherenceEngine.triggerMicroFeedback(isOnTrack: isOnTrack)
            dismiss()
        } catch {
            isSaving = false
        }
    }
}

#Preview {
    LogMealView()
}
