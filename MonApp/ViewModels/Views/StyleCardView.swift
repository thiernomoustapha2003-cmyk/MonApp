//
//  StyleCardView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 20/06/2026.
//

import SwiftUI
import FirebaseFirestore

struct StyleCardView: View {
    
    let style: Style
    @State private var selectedBarber: Barber?
    @State private var showBarberDetail = false
    
    
    @State private var isLoadingBarber = false
    
    
    
    @State private var showComments = false
    @State private var isFavorite = false
    
    
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 12) {
            
            AsyncImage(url: URL(string: style.imageUrl)) { image in
                
                image
                    .resizable()
                    .scaledToFill()
                
            } placeholder: {
                
                ProgressView()
            }
            .frame(height: 220)
            .frame(maxWidth: .infinity)
            .clipped()
            .cornerRadius(18)
            
            Text(style.title)
                .font(.title3.bold())
            
            Text(style.description)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack {
                
                Label("\(Int(style.price)) €", systemImage: "eurosign.circle.fill")
                Spacer()
                
                Label("\(style.duration) min", systemImage: "clock.fill")
            }
            .font(.caption)
            
            HStack {
                
                Image(systemName: "person.crop.circle.fill")
                
                Text(style.barberName)
                
                Spacer()
                
                Button {
                    
                    StylesService.shared.toggleLike(style: style)
                    
                } label: {
                    
                    HStack {
                        
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        
                        Text("\(style.likesCount)")
                    }
                }
                
                Button {
                    
                    showComments = true
                    
                } label: {
                    
                    HStack {
                        
                        Image(systemName: "message.fill")
                            .foregroundColor(.blue)
                        
                        Text("\(style.commentsCount)")
                    }
                }
                
                Button {
                    
                    StylesService.shared.addFavorite(style: style)
                    
                } label: {
                    
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            Button {
                loadBarberAndOpen()
            } label: {
                Text(isLoadingBarber ? "Chargement..." : "Réserver maintenant")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .disabled(isLoadingBarber)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(22)
        .shadow(radius: 3)
        .fullScreenCover(isPresented: $showBarberDetail) {
            if let barber = selectedBarber {
                BarberDetailView(barber: barber)
            }
        }
        
        .sheet(isPresented: $showComments) {
            
            StyleCommentsView(style: style)
        }
    }
    
    func loadBarberAndOpen() {
        isLoadingBarber = true

        Firestore.firestore()
            .collection("users")
            .document(style.barberId)
            .getDocument { snapshot, error in

                DispatchQueue.main.async {
                    isLoadingBarber = false
                }

                if let error = error {
                    print("❌ Erreur chargement coiffeur:", error.localizedDescription)
                    return
                }

                guard let snapshot = snapshot,
                      snapshot.exists,
                      let data = snapshot.data() else {
                    print("❌ Coiffeur introuvable dans users pour id:", style.barberId)
                    return
                }

                let barber = Barber(
                    authId: data["uid"] as? String ?? snapshot.documentID,
                    name: data["name"] as? String ?? data["fullName"] as? String ?? style.barberName,
                    city: data["city"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    price: data["price"] as? Double ?? 0,
                    street: data["street"] as? String ?? data["streetAddress"] as? String ?? "",
                    houseNumber: data["houseNumber"] as? String ?? data["buildingNumber"] as? String ?? "",
                    postalCode: data["postalCode"] as? String ?? "",
                    phone: data["phone"] as? String ?? "",
                    latitude: data["latitude"] as? Double ?? 0,
                    longitude: data["longitude"] as? Double ?? 0,
                    services: data["services"] as? [String] ?? [],
                    imageUrl: data["imageUrl"] as? String,
                    isFavorite: false,
                    isPro: data["isPro"] as? Bool ?? false,
                    isCertified: data["isCertified"] as? Bool ?? false,
                    acceptsOnlinePayment: data["acceptsOnlinePayment"] as? Bool ?? false,
                    platformCommissionRate: data["platformCommissionRate"] as? Double ?? 0.15,
                    stripeAccountId: data["stripeAccountId"] as? String,
                    payoutEnabled: data["payoutEnabled"] as? Bool ?? false,
                    averageRating: data["averageRating"] as? Double ?? 0,
                    totalReviews: data["totalReviews"] as? Int ?? 0,
                    isCurrentlyAvailable: true
                )

                DispatchQueue.main.async {
                    selectedBarber = barber
                    showBarberDetail = true
                }
            }
    }
    
}
