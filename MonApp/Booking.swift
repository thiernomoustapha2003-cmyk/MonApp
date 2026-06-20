import Foundation

struct Booking: Identifiable {
    
    // ✅ TES CHAMPS (TOUS GARDÉS — PAS TOUCHÉS)
    var id: String
    var barberId: String
    var barberName: String
    var clientName: String
    var clientId: String
    var date: String
    var time: String
    var status: String
    var slotId: String
    // ================= UI CLIENT =================

    /// Nom du service réservé (ex: Dégradé + Barbe)
    var serviceName: String?

    /// Prix payé
    var price: Double?

    /// Photo du coiffeur affichée dans "Mes réservations"
    var barberImage: String?
    // =====================================================
    // ✅ NOUVEAUX CHAMPS (PAIEMENT + ESCROW + CERTIFICATION)
    // =====================================================
    
    /// "not_paid", "paid"
    var paymentStatus: String
    
    /// "not_started", "held", "released", "refunded"
    var escrowStatus: String
    
    /// Montant total payé par le client
    var heldAmount: Double?
    
    /// Montant reçu par le coiffeur après commission
    var barberPaidAmount: Double?
    
    /// Ta commission CUTLY
    var platformCommission: Double?
    
    /// Pour savoir si le coiffeur est pro
    var barberIsPro: Bool
    
    /// Pour savoir si le coiffeur est certifié
    var barberIsCertified: Bool
    
    /// Date de création
    var createdAt: Date?
    
    /// Date où le client a confirmé la prestation
    var clientConfirmedAt: Date?
    
    /// Date où l’argent a été versé au coiffeur
    var paidToBarberAt: Date?
    
    /// Date de remboursement si annulé
    var refundedAt: Date?
    
    // =====================================================
    // ✅ INIT COMPLET (PROPRE)
    // =====================================================
    init(
        id: String,
        barberId: String,
        barberName: String,
        clientName: String,
        clientId: String,
        date: String,
        time: String,
        status: String,
        slotId: String = "",
        serviceName: String? = nil,
        price: Double? = nil,
        barberImage: String? = nil,
        paymentStatus: String = "not_paid",
        escrowStatus: String = "not_started",
        heldAmount: Double? = nil,
        barberPaidAmount: Double? = nil,
        platformCommission: Double? = nil,
        barberIsPro: Bool = false,
        barberIsCertified: Bool = false,
        createdAt: Date? = nil,
        clientConfirmedAt: Date? = nil,
        paidToBarberAt: Date? = nil,
        refundedAt: Date? = nil
    ) {
        self.id = id
        self.barberId = barberId
        self.barberName = barberName
        self.clientName = clientName
        self.clientId = clientId
        self.date = date
        self.time = time
        self.status = status
        self.slotId = slotId
        self.serviceName = serviceName
        self.price = price
        self.barberImage = barberImage
        
        self.paymentStatus = paymentStatus
        self.escrowStatus = escrowStatus
        self.heldAmount = heldAmount
        self.barberPaidAmount = barberPaidAmount
        self.platformCommission = platformCommission
        self.barberIsPro = barberIsPro
        self.barberIsCertified = barberIsCertified
        self.createdAt = createdAt
        self.clientConfirmedAt = clientConfirmedAt
        self.paidToBarberAt = paidToBarberAt
        self.refundedAt = refundedAt
    }
}
