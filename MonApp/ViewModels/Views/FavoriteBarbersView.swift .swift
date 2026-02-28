import SwiftUI

struct FavoriteBarbersView: View {
    @EnvironmentObject var viewModel: BarberViewModel


    var favoriteBarbers: [Barber] {
        viewModel.barbers.filter { $0.isFavorite ?? false }
    }

    var body: some View {
        NavigationView {
            List(favoriteBarbers) { barber in
                VStack(alignment: .leading) {
                    Text(barber.name)
                        .font(.headline)
                    Text(barber.city)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("❤️ Favoris")
        }
    }
}
