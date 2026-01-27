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

                    Button {
                        showDataView = true
                    } label: {
                        Image(systemName: "chart.bar.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 8)
                }

                Spacer()

                Button {
                    showLogMeal = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.title2.weight(.semibold))
                        Text("Log Meal")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(.blue)
                    .clipShape(Capsule())
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showLogMeal) {
            LogMealView()
        }
        .sheet(isPresented: $showDataView) {
            DataView()
        }
    }
}

#Preview {
    MainView()
}
