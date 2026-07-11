//
//  MarketplaceWalletModels.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import Foundation
import FirebaseFirestore

// MARK: - Wallet Transaction Type

enum MarketplaceWalletTransactionType: String, Codable, CaseIterable, Identifiable {
    case sale
    case payout
    case refund
    case cashback
    case bonus
    case platformFee
    case adjustment
    case disputeHold
    case disputeRelease
    case withdrawalFailed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sale: return "Vente"
        case .payout: return "Retrait"
        case .refund: return "Remboursement"
        case .cashback: return "Cashback"
        case .bonus: return "Bonus"
        case .platformFee: return "Commission Cutly"
        case .adjustment: return "Ajustement"
        case .disputeHold: return "Blocage litige"
        case .disputeRelease: return "Déblocage litige"
        case .withdrawalFailed: return "Retrait échoué"
        }
    }
}

// MARK: - Wallet Transaction Status

enum MarketplaceWalletTransactionStatus: String, Codable, CaseIterable, Identifiable {
    case pending
    case processing
    case completed
    case failed
    case cancelled
    case underReview

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pending: return "En attente"
        case .processing: return "En traitement"
        case .completed: return "Terminé"
        case .failed: return "Échoué"
        case .cancelled: return "Annulé"
        case .underReview: return "En vérification"
        }
    }
}

// MARK: - Wallet Account Type

enum MarketplaceWalletAccountType: String, Codable, CaseIterable, Identifiable {
    case buyer
    case seller
    case professionalStore
    case platform
    case partner

    var id: String { rawValue }

    var title: String {
        switch self {
        case .buyer: return "Acheteur"
        case .seller: return "Vendeur"
        case .professionalStore: return "Boutique professionnelle"
        case .platform: return "Plateforme Cutly"
        case .partner: return "Partenaire"
        }
    }
}

// MARK: - Withdrawal Method

enum MarketplaceWithdrawalMethod: String, Codable, CaseIterable, Identifiable {
    case bankAccount
    case stripeConnect
    case paypal
    case orangeMoney
    case wave
    case mtnMobileMoney
    case moovMoney
    case airtelMoney
    case mpesa
    case freeMoney
    case tmoney
    case flooz
    case manual

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bankAccount: return "Compte bancaire"
        case .stripeConnect: return "Stripe Connect"
        case .paypal: return "PayPal"
        case .orangeMoney: return "Orange Money"
        case .wave: return "Wave"
        case .mtnMobileMoney: return "MTN Mobile Money"
        case .moovMoney: return "Moov Money"
        case .airtelMoney: return "Airtel Money"
        case .mpesa: return "M-Pesa"
        case .freeMoney: return "Free Money"
        case .tmoney: return "TMoney"
        case .flooz: return "Flooz"
        case .manual: return "Manuel"
        }
    }
}

// MARK: - Marketplace Wallet

struct MarketplaceWallet: Codable, Identifiable, Hashable {
    @DocumentID var id: String?

    var userId: String
    var storeId: String?

    var accountType: MarketplaceWalletAccountType
    var currency: MarketplaceCurrency

    var availableBalance: Double
    var pendingBalance: Double
    var lifetimeEarnings: Double
    var lifetimeWithdrawn: Double
    var lifetimeRefunded: Double
    var lifetimeFeesPaid: Double

    var isPayoutEnabled: Bool
    var isUnderReview: Bool
    var defaultWithdrawalMethod: MarketplaceWithdrawalMethod?

    var aiRiskLevel: MarketplaceRiskLevel
    var aiWarnings: [String]

    var createdAt: Timestamp?
    var updatedAt: Timestamp?

    init(
        id: String? = nil,
        userId: String,
        storeId: String? = nil,
        accountType: MarketplaceWalletAccountType = .buyer,
        currency: MarketplaceCurrency = .eur,
        availableBalance: Double = 0,
        pendingBalance: Double = 0,
        lifetimeEarnings: Double = 0,
        lifetimeWithdrawn: Double = 0,
        lifetimeRefunded: Double = 0,
        lifetimeFeesPaid: Double = 0,
        isPayoutEnabled: Bool = false,
        isUnderReview: Bool = false,
        defaultWithdrawalMethod: MarketplaceWithdrawalMethod? = nil,
        aiRiskLevel: MarketplaceRiskLevel = .low,
        aiWarnings: [String] = [],
        createdAt: Timestamp? = nil,
        updatedAt: Timestamp? = nil
    ) {
        self.id = id
        self.userId = userId
        self.storeId = storeId
        self.accountType = accountType
        self.currency = currency
        self.availableBalance = availableBalance
        self.pendingBalance = pendingBalance
        self.lifetimeEarnings = lifetimeEarnings
        self.lifetimeWithdrawn = lifetimeWithdrawn
        self.lifetimeRefunded = lifetimeRefunded
        self.lifetimeFeesPaid = lifetimeFeesPaid
        self.isPayoutEnabled = isPayoutEnabled
        self.isUnderReview = isUnderReview
        self.defaultWithdrawalMethod = defaultWithdrawalMethod
        self.aiRiskLevel = aiRiskLevel
        self.aiWarnings = aiWarnings
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var availableFormatted: String {
        MarketplacePrice(amount: availableBalance, currency: currency).formatted
    }

    var pendingFormatted: String {
        MarketplacePrice(amount: pendingBalance, currency: currency).formatted
    }
}

// MARK: - Marketplace Wallet Transaction

struct MarketplaceWalletTransaction: Codable, Identifiable, Hashable {
    @DocumentID var id: String?

    var walletId: String
    var userId: String
    var storeId: String?

    var type: MarketplaceWalletTransactionType
    var status: MarketplaceWalletTransactionStatus

    var title: String
    var description: String?

    var amount: MarketplacePrice
    var balanceBefore: MarketplacePrice?
    var balanceAfter: MarketplacePrice?

    var orderId: String?
    var paymentId: String?
    var refundId: String?
    var disputeId: String?
    var withdrawalId: String?

    var externalReferenceId: String?

    var aiRiskLevel: MarketplaceRiskLevel
    var aiWarnings: [String]

    var createdAt: Timestamp?
    var completedAt: Timestamp?
    var updatedAt: Timestamp?

    init(
        id: String? = nil,
        walletId: String,
        userId: String,
        storeId: String? = nil,
        type: MarketplaceWalletTransactionType,
        status: MarketplaceWalletTransactionStatus = .pending,
        title: String,
        description: String? = nil,
        amount: MarketplacePrice,
        balanceBefore: MarketplacePrice? = nil,
        balanceAfter: MarketplacePrice? = nil,
        orderId: String? = nil,
        paymentId: String? = nil,
        refundId: String? = nil,
        disputeId: String? = nil,
        withdrawalId: String? = nil,
        externalReferenceId: String? = nil,
        aiRiskLevel: MarketplaceRiskLevel = .low,
        aiWarnings: [String] = [],
        createdAt: Timestamp? = nil,
        completedAt: Timestamp? = nil,
        updatedAt: Timestamp? = nil
    ) {
        self.id = id
        self.walletId = walletId
        self.userId = userId
        self.storeId = storeId
        self.type = type
        self.status = status
        self.title = title
        self.description = description
        self.amount = amount
        self.balanceBefore = balanceBefore
        self.balanceAfter = balanceAfter
        self.orderId = orderId
        self.paymentId = paymentId
        self.refundId = refundId
        self.disputeId = disputeId
        self.withdrawalId = withdrawalId
        self.externalReferenceId = externalReferenceId
        self.aiRiskLevel = aiRiskLevel
        self.aiWarnings = aiWarnings
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Marketplace Withdrawal Account

struct MarketplaceWithdrawalAccount: Codable, Identifiable, Hashable {
    @DocumentID var id: String?

    var userId: String
    var storeId: String?

    var method: MarketplaceWithdrawalMethod
    var label: String

    var accountHolderName: String?
    var bankName: String?
    var ibanLast4: String?
    var swiftCode: String?

    var phoneNumber: String?
    var countryCode: String?

    var externalAccountId: String?
    var isDefault: Bool
    var isVerified: Bool
    var isActive: Bool

    var createdAt: Timestamp?
    var verifiedAt: Timestamp?
    var updatedAt: Timestamp?

    init(
        id: String? = nil,
        userId: String,
        storeId: String? = nil,
        method: MarketplaceWithdrawalMethod,
        label: String,
        accountHolderName: String? = nil,
        bankName: String? = nil,
        ibanLast4: String? = nil,
        swiftCode: String? = nil,
        phoneNumber: String? = nil,
        countryCode: String? = nil,
        externalAccountId: String? = nil,
        isDefault: Bool = false,
        isVerified: Bool = false,
        isActive: Bool = true,
        createdAt: Timestamp? = nil,
        verifiedAt: Timestamp? = nil,
        updatedAt: Timestamp? = nil
    ) {
        self.id = id
        self.userId = userId
        self.storeId = storeId
        self.method = method
        self.label = label
        self.accountHolderName = accountHolderName
        self.bankName = bankName
        self.ibanLast4 = ibanLast4
        self.swiftCode = swiftCode
        self.phoneNumber = phoneNumber
        self.countryCode = countryCode
        self.externalAccountId = externalAccountId
        self.isDefault = isDefault
        self.isVerified = isVerified
        self.isActive = isActive
        self.createdAt = createdAt
        self.verifiedAt = verifiedAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Marketplace Withdrawal

struct MarketplaceWithdrawal: Codable, Identifiable, Hashable {
    @DocumentID var id: String?

    var walletId: String
    var userId: String
    var storeId: String?

    var withdrawalAccountId: String?
    var method: MarketplaceWithdrawalMethod
    var status: MarketplaceWalletTransactionStatus

    var amount: MarketplacePrice
    var fee: MarketplacePrice?
    var netAmount: MarketplacePrice?

    var externalPayoutId: String?
    var failureReason: String?

    var aiRiskLevel: MarketplaceRiskLevel
    var aiWarnings: [String]

    var requestedAt: Timestamp?
    var processingAt: Timestamp?
    var completedAt: Timestamp?
    var failedAt: Timestamp?
    var updatedAt: Timestamp?

    init(
        id: String? = nil,
        walletId: String,
        userId: String,
        storeId: String? = nil,
        withdrawalAccountId: String? = nil,
        method: MarketplaceWithdrawalMethod,
        status: MarketplaceWalletTransactionStatus = .pending,
        amount: MarketplacePrice,
        fee: MarketplacePrice? = nil,
        netAmount: MarketplacePrice? = nil,
        externalPayoutId: String? = nil,
        failureReason: String? = nil,
        aiRiskLevel: MarketplaceRiskLevel = .low,
        aiWarnings: [String] = [],
        requestedAt: Timestamp? = nil,
        processingAt: Timestamp? = nil,
        completedAt: Timestamp? = nil,
        failedAt: Timestamp? = nil,
        updatedAt: Timestamp? = nil
    ) {
        self.id = id
        self.walletId = walletId
        self.userId = userId
        self.storeId = storeId
        self.withdrawalAccountId = withdrawalAccountId
        self.method = method
        self.status = status
        self.amount = amount
        self.fee = fee
        self.netAmount = netAmount
        self.externalPayoutId = externalPayoutId
        self.failureReason = failureReason
        self.aiRiskLevel = aiRiskLevel
        self.aiWarnings = aiWarnings
        self.requestedAt = requestedAt
        self.processingAt = processingAt
        self.completedAt = completedAt
        self.failedAt = failedAt
        self.updatedAt = updatedAt
    }
}
