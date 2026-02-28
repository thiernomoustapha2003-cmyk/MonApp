import SwiftUI

struct ClientExportView: View {

    @State private var isLoading = true
    @State private var exportURL: URL?
    @State private var showShare = false

    var body: some View {

        VStack(spacing: 25) {

            if isLoading {
                ProgressView("Préparation du fichier...")
                    .padding(.top, 40)
            }

            else if exportURL == nil {
                Text("Impossible de générer le fichier")
                    .foregroundColor(.red)
            }

            else {
                Text("Fichier prêt !")
                    .font(.title3)

                Button("Exporter les clients") {
                    showShare = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .onAppear {
            generate()
        }
        .sheet(isPresented: $showShare) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }

    func generate() {
        ClientExporter.generateClientsCSV { url in
            DispatchQueue.main.async {
                self.exportURL = url
                self.isLoading = false
            }
        }
    }
}
