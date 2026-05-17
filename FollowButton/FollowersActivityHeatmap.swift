import SwiftUI

// =====================================================
// MODELE DE DONNEES
// =====================================================
// Chaque carré de la heatmap représente :
// - un jour
// - une heure
// - un niveau d'activité des followers

struct ActivityCell: Identifiable {
    
    let id = UUID()
    
    // Jour de la semaine (Lun, Mar, etc)
    let day: String
    
    // Heure de la journée (0 → 23)
    let hour: Int
    
    // Nombre de followers actifs à ce moment
    let value: Int
}


// =====================================================
// VUE PRINCIPALE HEATMAP
// =====================================================

struct FollowersActivityHeatmap: View {
    
    // Données envoyées par le ViewModel
    var data: [ActivityCell]
    
    // Jours affichés
    let days = ["L", "M", "M", "J", "V", "S", "D"]
    
    
    // =====================================================
    // Valeur maximale d'activité
    // Sert à calculer les couleurs
    // =====================================================
    
    var maxValue: Int {
        data.map{$0.value}.max() ?? 1
    }
    
    
    // =====================================================
    // INTERFACE
    // =====================================================
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 16) {
            
            
            // =================================================
            // TITRE
            // =================================================
            
            Text("Activité des followers par jour et heure")
                .font(.headline)
            
            
            // =================================================
            // HEATMAP
            // =================================================
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 7),
                spacing: 6
            ) {
                
                // Chaque cellule = 1 heure d'un jour
                
                ForEach(data) { cell in
                    
                    Rectangle()
                        .fill(color(for: cell.value))
                        .frame(height: 18)
                        .cornerRadius(3)
                }
            }
            
            
            // =================================================
            // LEGENDE
            // =================================================
            // Cette partie explique la signification des couleurs
            
            VStack(alignment: .leading, spacing: 6) {
                
                Text("Légende")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack(spacing: 16) {
                    
                    legend(color: .gray.opacity(0.2), text: "Activité faible")
                    
                    legend(color: .blue.opacity(0.4), text: "Activité moyenne")
                    
                    legend(color: .blue.opacity(0.7), text: "Activité élevée")
                    
                    legend(color: .blue, text: "Activité très élevée")
                }
            }
            
            
            // =================================================
            // EXPLICATION SIMPLE
            // =================================================
            
            Text("Plus la couleur est bleue, plus tes followers sont connectés à ce moment.")
                .font(.caption)
                .foregroundColor(.gray)
            
        }
    }
    
    
    // =====================================================
    // COULEUR DES CELLULES
    // =====================================================
    
    func color(for value: Int) -> Color {
        
        let ratio = Double(value) / Double(maxValue)
        
        if ratio > 0.75 { return .blue }
        if ratio > 0.5 { return .blue.opacity(0.7) }
        if ratio > 0.25 { return .blue.opacity(0.4) }
        
        return .gray.opacity(0.2)
    }
    
    
    // =====================================================
    // LEGENDE VISUELLE
    // =====================================================
    
    func legend(color: Color, text: String) -> some View {
        
        HStack(spacing: 4) {
            
            Rectangle()
                .fill(color)
                .frame(width: 12, height: 12)
                .cornerRadius(2)
            
            Text(text)
                .font(.caption)
        }
    }
}
