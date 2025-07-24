//
//  Ledger.swift
//  
//

import Foundation

extension Array where Array.Element == Ledger.Event {
    func event(assetID: String) -> Ledger.Event? {
        self.first(where: {
            guard case let Ledger.Event.asset(transaction: _, accountID: id) = $0 else {
                return false
            }

            return assetID == id
        })
    }

    func event(liabilityID: String) -> Ledger.Event? {
        self.first(where: {
            guard case let Ledger.Event.liability(transaction: _, accountID: id) = $0 else {
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
    var id: String
    var assets: [Asset] = []
    var liabilities: [Liability] = []
    var equities: [Equity] = []

    func currentBalance() -> Decimal {
        let assetSum = assets.map { $0.currentBalance() }.reduce(Decimal.zero, +)
        let liabilitySum = liabilities.map { $0.currentBalance() }.reduce(Decimal.zero, +)
        let equitySum = equities.map { $0.currentBalance() }.reduce(Decimal.zero, +)

        return assetSum - liabilitySum - equitySum
    }

    func tick(event: Event) -> Self {
        switch event {
        case .asset(let transaction, let accountID):
            return Ledger(
                id: id,
                assets: assets.map { $0.id == accountID ? $0.transacted(transaction) : $0 },
                liabilities: liabilities,
                equities: equities
            )
        case .liability(let transaction, let accountID):
            return Ledger(
                id: id,
                assets: assets,
                liabilities: liabilities.map { $0.id == accountID ? $0.transacted(transaction) : $0 },
                equities: equities
            )
        case .equity(transaction: let transaction, accountID: let accountID):
            return Ledger(
                id: id,
                assets: assets,
                liabilities: liabilities,
                equities: equities.map { $0.id == accountID ? $0.transacted(transaction) : $0 }
            )
        }
    }

    func evented(_ events: [Event]) -> Self {
        var eventedAssets = assets
        var eventedLiabilities = liabilities
        var eventedEquities = equities

        for event in events {
            switch event {
            case .asset(let transaction, let id):
                eventedAssets = eventedAssets.map { $0.id == id ? $0.transacted(transaction) : $0 }
            case .liability(let transaction, let id):
                eventedLiabilities = eventedLiabilities.map { $0.id == id ? $0.transacted(transaction) : $0 }
            case .equity(transaction: let transaction, accountID: let id):
                eventedEquities = eventedEquities.map { $0.id == id ? $0.transacted(transaction) : $0 }
            }
        }
        
        return Self(
            id: id,
            assets: eventedAssets,
            liabilities: eventedLiabilities,
            equities: eventedEquities
        )
    }

    enum Event: Equatable {
        case asset(transaction: Asset.Transaction, accountID: String)
        case liability(transaction: Liability.Transaction, accountID: String)
        case equity(transaction: Equity.Transaction, accountID: String)

        var amount: Decimal {
            switch self {
            case .asset(
                transaction: let transaction,
                accountID: _
            ):
                return transaction.amount
            case .liability(
                transaction: let transaction,
                accountID: _
            ):
                return transaction.amount
            case .equity(
                transaction: let transaction,
                accountID: _
            ):
                return transaction.amount
            }
        }

        var id: String {
            switch self {
            case .asset(
                transaction: _,
                accountID: let id
            ):
                return id
            case .liability(
                transaction: _,
                accountID: let id
            ):
                return id
            case .equity(
                transaction: _,
                accountID: let id
            ):
                return id
            }
        }
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
            Event.asset(transaction: $0.0, accountID: $0.1)
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
            Event.liability(transaction: $0.0, accountID: $0.1)
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
            liabilities: liabilities,
            equities: equities
        )
    }

    func adding(_ liability: Liability) -> Self {
        return Self(
            id: id,
            assets: assets,
            liabilities: liabilities + [liability],
            equities: equities
        )
    }

    func adding(_ equity: Equity) -> Self {
        return Self(
            id: id,
            assets: assets,
            liabilities: liabilities,
            equities: equities + [equity]
        )
    }
}

extension Ledger {
    static func make(
        id: String = UUID().uuidString,
        assets: [Asset] = [],
        liabilities: [Liability] = [],
        equities: [Equity] = []
    ) -> Self {
        return Self(
            id: id,
            assets: assets,
            liabilities: liabilities,
            equities: equities
        )
    }
}
