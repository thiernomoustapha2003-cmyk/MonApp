import SwiftUI

struct ClientListView: View {
    
    @State private var clients: [Client] = []
    private let service = ClientService()
    
    var body: some View {
        List(clients) { client in
            
            NavigationLink {
                ClientDetailView(client: client)
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(client.name)
                            .font(.headline)
                        Text(client.phone)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    if client.isBlacklisted {
                        Text("🚫")
                    }
                }
            }
        }
        .navigationTitle("Mes Clients")
        .onAppear {
            service.fetchClients { result in
                self.clients = result
            }
        }
    }
}
