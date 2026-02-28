import SwiftUI

struct ClientDetailView: View {
    
    var client: Client
    private let service = ClientService()
    
    var body: some View {
        
        VStack(spacing: 20) {
            
            Text(client.name)
                .font(.title2)
                .bold()
            
            Text(client.phone)
            
            Toggle("Blacklister", isOn: Binding(
                get: { client.isBlacklisted },
                set: { value in
                    service.blacklistClient(
                        clientId: client.id ?? "",
                        value: value
                    )
                }
            ))
            .padding()
            
            NavigationLink("Ajouter note") {
                AddClientNoteView(client: client)
            }
            
            Spacer()
        }
        .padding()
    }
}
