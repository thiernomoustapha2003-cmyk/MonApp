import SwiftUI

struct ClientManagementView: View {
    
    @State private var exportURL: ShareableFile?
    
    var body: some View {
        
        NavigationStack {
            
            VStack(spacing: 30) {
                
                Text("👥 Gestion des Clients")
                    .font(.largeTitle)
                    .bold()
                
                // 🔹 Voir liste clients
                NavigationLink {
                    MesClientsView()
                } label: {
                    Text("Voir liste clients")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(12)
                }
                
                // 🔹 Export données clients
                Button {
                    exportClientsCSV()
                } label: {
                    Text("Exporter données clients")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            
            // ✅ SHEET déclenchée UNIQUEMENT quand URL existe
            .sheet(item: $exportURL) { file in
                ShareSheet(items: [file.url])
            }
        }
    }
}

// MARK: - Export
extension ClientManagementView {

    func exportClientsCSV() {

        generateClientsCSV { url in
            guard let url = url else { return }

            DispatchQueue.main.async {
                self.exportURL = ShareableFile(url: url)
            }
        }
    }
}
