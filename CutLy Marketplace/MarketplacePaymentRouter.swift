//
//  MarketplacePaymentRouter.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 07/07/2026.
//

import Foundation

enum MarketplacePaymentRoute {
    case stripe
    case paypal
    case applePay
    case bankCard
    case orangeMoney
    case wave
    case mtn
    case moov
    case mpesa
    case bankTransfer
    case wallet
    case manual
}

final class MarketplacePaymentRouter {

    static let shared = MarketplacePaymentRouter()

    private init() {}

    func route(
        provider: MarketplacePaymentProviderOption
    ) -> MarketplacePaymentRoute {

        switch provider {

        case .stripe:
            return .stripe

        case .paypal:
            return .paypal

        case .applePay:
            return .applePay

        case .cards:
            return .bankCard

        case .orangeMoney:
            return .orangeMoney

        case .wave:
            return .wave

        case .mtnMobileMoney:
            return .mtn

        case .moovMoney:
            return .moov

        case .mpesa:
            return .mpesa

        case .bankTransfer:
            return .bankTransfer

        case .walletCutly:
            return .wallet

        case .manual:
            return .manual

        default:
            return .manual
        }
    }
}
