import Foundation
import StripeCore
import StripePayments

struct StripeConfig {
    static let publishableKey =
    "pk_test_51SvGmGPeql1aQTZ7DPBJJUOW3cb6X5oNVfD0Zx4xvUEwrCVcAjUCHKuZUTk8bVxpvVHAorcZsSabltgJoigFXu1600Eey5pria"

    static func setup() {
        StripeAPI.defaultPublishableKey = publishableKey
    }
}

