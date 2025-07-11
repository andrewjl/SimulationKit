//
//  Ledger.swift
//  
//

import Foundation

extension Array where Array.Element == Asset {
    func event(_ event: Ledger.Event) -> Self {
        guard case Ledger.Event.asset(transaction: let transaction, id: let id) = event else {
            return self
        }

        return self.map { $0.id == id ? $0.transacted(transaction) : $0 }
    }

    func currentBalance() -> Decimal {
        self.map { $0.currentBalance() }.reduce(Decimal.zero, +)
    }

    func adjusted(by percentageRate: Int) -> Self {
        self.map { $0.adjusted(by: percentageRate) }
    }

    func adjustmentTransactions(by percentageRate: Int) -> [Array.Element.Transaction] {
        self.map { $0.adjustmentTransaction(by: percentageRate) }
    }
}

extension Array where Array.Element == Liability {
    func event(_ event: Ledger.Event) -> Self {
        guard case Ledger.Event.liability(transaction: let transaction, id: let id) = event else {
            return self
        }

        return self.map { $0.id == id ? $0.transacted(transaction) : $0 }
    }

    func currentBalance() -> Decimal {
        self.map { $0.currentBalance() }.reduce(Decimal.zero, +)
    }

    func adjusted(
        by percentageRate: Int
    ) -> Self {
        self.map { $0.adjusted(by: percentageRate) }
    }

    func adjustmentTransactions(
        by percentageRate: Int
    ) -> [Array.Element.Transaction] {
        self.map { $0.adjustmentTransaction(by: percentageRate) }
    }
}

extension Array where Array.Element == Ledger.Event {
    func event(assetID: UInt) -> Ledger.Event? {
        self.first(where: {
            guard case let Ledger.Event.asset(transaction: _, id: id) = $0 else {
                return false
            }

            return assetID == id
        })
    }

    func event(liabilityID: UInt) -> Ledger.Event? {
        self.first(where: {
            guard case let Ledger.Event.liability(transaction: _, id: id) = $0 else {
                return false
            }

            return liabilityID == id
        })
    }
}

extension Array where Array.Element == Ledger {
    func currentBalances() -> [Decimal] {
        return self.map { $0.currentBalance() }
    }
}

struct Ledger: Equatable {
    static var autoincrementedID: UInt = 0

    var id: UInt
    var assets: [Asset] = []
    var liabilities: [Liability] = []

    func currentBalance() -> Decimal {
        let assetSum = assets.map { $0.currentBalance() }.reduce(Decimal.zero, +)
        let liabilitySum = liabilities.map { $0.currentBalance() }.reduce(Decimal.zero, +)

        return assetSum - liabilitySum
    }

    func tick(event: Event) -> Self {
        switch event {
        case .asset(let transaction, let id):
            return Ledger(
                id: id,
                assets: assets.map { $0.id == id ? $0.transacted(transaction) : $0 },
                liabilities: liabilities
            )
        case .liability(let transaction, let id):
            return Ledger(
                id: id,
                assets: assets,
                liabilities: liabilities.map { $0.id == id ? $0.transacted(transaction) : $0 }
            )
        }
    }

    func evented(_ events: [Event]) -> Self {
        var eventedAssets = assets
        var eventedLiabilities = liabilities

        for event in events {
            switch event {
            case .asset(let transaction, let id):
                eventedAssets = eventedAssets.map { $0.id == id ? $0.transacted(transaction) : $0 }
            case .liability(let transaction, let id):
                eventedLiabilities = eventedLiabilities.map { $0.id == id ? $0.transacted(transaction) : $0 }
            }
        }
        
        return Self(
            id: id,
            assets: eventedAssets,
            liabilities: eventedLiabilities
        )
    }

    enum Event: Equatable {
        case asset(transaction: Asset.Transaction, id: UInt)
        case liability(transaction: Liability.Transaction, id: UInt)
    }

    func eventsAdjustingAllAssetBalances(
        by rate: Int
    ) -> [Event] {
        return zip(
            assets
                .adjustmentTransactions(
                    by: rate
                ),
            assets.map { $0.id }
        ).map {
            Event.asset(transaction: $0.0, id: $0.1)
        }
    }

    func eventsAdjustingAllLiabilityBalances(
        by rate: Int
    ) -> [Event] {
        return zip(
            liabilities
                .adjustmentTransactions(
                    by: rate
                ),
            liabilities.map { $0.id }
        ).map {
            Event.liability(transaction: $0.0, id: $0.1)
        }
    }

    func eventsAdjustingAllBalances(
        by rate: Int
    ) -> [Event] {
        self.eventsAdjustingAllAssetBalances(
            by: rate
        ) + self.eventsAdjustingAllLiabilityBalances(
            by: rate
        )
    }
}

extension Ledger {
    func adjustAllAssetBalances(
        by rate: Int
    ) -> Self {
        self.evented(
            self.eventsAdjustingAllAssetBalances(by: rate)
        )
    }

    func adjustAllLiabilityBalances(
        by rate: Int
    ) -> Self {
        self.evented(
            self.eventsAdjustingAllLiabilityBalances(by: rate)
        )
    }
}

extension Ledger {
    func adding(_ asset: Asset) -> Self {
        return Self(
            id: id,
            assets: assets + [asset],
            liabilities: liabilities
        )
    }

    func adding(_ liability: Liability) -> Self {
        return Self(
            id: id,
            assets: assets,
            liabilities: liabilities + [liability]
        )
    }
}

extension Ledger {
    static func make(
        assets: [Asset],
        liabilities: [Liability]
    ) -> Self {
        defer {
            Self.autoincrementedID += 1
        }
        return Self(
            id: Self.autoincrementedID,
            assets: assets,
            liabilities: liabilities
        )
    }
}
