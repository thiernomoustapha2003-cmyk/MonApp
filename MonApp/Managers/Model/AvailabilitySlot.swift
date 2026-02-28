import Foundation
import FirebaseFirestore

// =========================================
// ✅ STATUT DU CRÉNEAU (CORRECT)
// =========================================
enum SlotStatus: String, Codable {
    case available = "available"
    case booked = "booked"
    case pending = "pending"
    case notWorking = "notWorking"
}

// =========================================
// ✅ MODÈLE AVAILABILITY SLOT — VERSION PROPRE
// =========================================
struct AvailabilitySlot: Identifiable, Codable {

    /// ✅ ID du DOCUMENT Firestore (géré automatiquement)
    @DocumentID
    var id: String?

    /// ✅ ID DU DOCUMENT BARBER (PAS authId)
    var barberId: String

    /// ✅ DATE DU JOUR (00:00)
    var date: Date

    /// ✅ HEURE DE DÉBUT
    var startTime: Date

    /// ✅ HEURE DE FIN
    var endTime: Date

    /// ✅ STATUT
    var status: SlotStatus

    // =========================================
    // ✅ INIT CLAIR ET SÛR (OPTIONNEL MAIS PROPRE)
    // =========================================
    init(
        id: String? = nil,
        barberId: String,
        date: Date,
        startTime: Date,
        endTime: Date,
        status: SlotStatus = .available
    ) {
        self.id = id
        self.barberId = barberId
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
    }
}
