//
//  Duality.swift
//

import Foundation

struct Duality: Equatable {
    var asset: Asset
    var liability: Liability

    init(
        asset: Asset,
        liability: Liability
    ) {
        precondition(
            asset.currentBalance() == liability.currentBalance(),
            "Asset and liability must be equal"
        )
        self.asset = asset
        self.liability = liability
    }
}

extension Duality {
    func changeAsset(amount: Decimal) -> Self {
        return Self(
            asset: asset.transacted(Asset.Transaction(amount: amount)),
            liability: liability.transacted(Liability.Transaction(amount: -amount))
        )
    }

    func changeLiability(amount: Decimal) -> Self {
        return Self(
            asset: asset.transacted(Asset.Transaction(amount: -amount)),
            liability: liability.transacted(Liability.Transaction(amount: amount))
        )
    }
}
