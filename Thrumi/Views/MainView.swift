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
