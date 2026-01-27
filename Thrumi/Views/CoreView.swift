import SwiftUI

struct CoreView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "atom")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)

                Text("Fusion Core")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text("3D Core will render here")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
        }
    }
}

#Preview {
    CoreView()
}
