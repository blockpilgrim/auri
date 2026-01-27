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
                Picker("Entry Mode", selection: $entryMode) {
                    ForEach(EntryMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
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
            .background(Color(uiColor: .systemGroupedBackground))
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
