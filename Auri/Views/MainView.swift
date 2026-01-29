import SwiftUI

struct MainView: View {
    @State private var showLogMeal = false
    @State private var showDataView = false

    var body: some View {
        ZStack {
            CoreView()

            VStack {
                HStack {
                    Spacer()
                    DataViewButton { showDataView = true }
                        .padding(.trailing, 20)
                        .padding(.top, 8)
                }

                Spacer()

                Button {
                    showLogMeal = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.subheadline.weight(.semibold))
                        Text("Log Meal")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 11)
                    .glassCapsule()
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showLogMeal) {
            LogMealView()
                .presentationBackground(.black)
        }
        .sheet(isPresented: $showDataView) {
            DataView()
                .presentationBackground(.black)
        }
    }
}

#Preview {
    MainView()
}
