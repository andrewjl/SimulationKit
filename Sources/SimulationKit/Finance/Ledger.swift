//
//  Ledger.swift
//  
//

import Foundation

extension Asset {
    func increased(by percentageRate: UInt) -> Self {
        let gain = currentBalance().decimalizedAdjustment(percentage: percentageRate)
        return self.transacted(
            .increasing(by: gain)
        )
    }

    func increaseTransaction(by percentageRate: UInt) -> Self.Transaction {
        let gain = currentBalance().decimalizedAdjustment(percentage: percentageRate)
        return .increasing(by: gain)
    }
}

extension Liability {
    func increased(by percentageRate: UInt) -> Self {
        let gain = currentBalance().decimalizedAdjustment(percentage: percentageRate)
        return self.transacted(
            .increasing(by: gain)
        )
    }

    func increaseTransaction(by percentageRate: UInt) -> Self.Transaction {
        let gain = currentBalance().decimalizedAdjustment(percentage: percentageRate)
        return .increasing(by: gain)
    }
}

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

    func increased(by percentageRate: UInt) -> Self {
        self.map { $0.increased(by: percentageRate) }
    }

    func increaseTransactions(by percentageRate: UInt) -> [Array.Element.Transaction] {
        self.map { $0.increaseTransaction(by: percentageRate) }
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

    func increased(by percentageRate: UInt) -> Self {
        self.map { $0.increased(by: percentageRate) }
    }

    func increaseTransactions(by percentageRate: UInt) -> [Array.Element.Transaction] {
        self.map { $0.increaseTransaction(by: percentageRate) }
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

struct Ledger {
    var assets: [Asset]
    var liabilities: [Liability]

    func currentBalance() -> Decimal {
        let assetSum = assets.map { $0.currentBalance() }.reduce(Decimal.zero, +)
        let liabilitySum = liabilities.map { $0.currentBalance() }.reduce(Decimal.zero, +)

        return assetSum - liabilitySum
    }

    func tick(tick: Tick) -> Self {
        let ledger = Ledger(
            assets: assets.map { $0.tick() },
            liabilities: liabilities.map { $0.tick() }
        )

        return ledger
    }

    func tick(event: Event) -> Self {
        switch event {
        case .asset(let transaction, let id):
            return Ledger(
                assets: assets.map { $0.id == id ? $0.transacted(transaction) : $0 },
                liabilities: liabilities
            )
        case .liability(let transaction, let id):
            return Ledger(
                assets: assets,
                liabilities: liabilities.map { $0.id == id ? $0.transacted(transaction) : $0 }
            )
        }
    }

    func tick(events: [Event]) -> Self {
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
            assets: eventedAssets,
            liabilities: eventedLiabilities
        )
    }

    func asPoints(tick: Tick) -> Points {
        let assetBalances: [UInt: Decimal] = Dictionary(uniqueKeysWithValues: assets.map { ($0.id, $0.currentBalance()) })
        let liabilityBalances = Dictionary(uniqueKeysWithValues: liabilities.map { ($0.id, $0.currentBalance()) })
        let assetRates = Dictionary(uniqueKeysWithValues: assets.map { ($0.id, $0.rate) })
        let liabilityRates = Dictionary(uniqueKeysWithValues: liabilities.map { ($0.id, $0.rate) })
        let timestamp = tick.time

        return Points(
            assetBalances: assetBalances,
            liabilityBalances: liabilityBalances,
            assetRates: assetRates,
            liabilityRates: liabilityRates,
            timestamp: timestamp
        )
    }

    enum Event {
        case asset(transaction: Asset.Transaction, id: UInt)
        case liability(transaction: Liability.Transaction, id: UInt)
    }
}

extension Ledger {
    struct Points: CustomStringConvertible {
        let assetBalances: [UInt: Decimal]
        let liabilityBalances: [UInt: Decimal]

        let assetRates: [UInt: UInt]
        let liabilityRates: [UInt: UInt]

        let timestamp: UInt32

        var description: String {
            return """
            Assets
            ID | Time | Balance
            \(assetBalances.map { "\($0.key) | \($0.value)" }.joined(separator: "\n"))

            Liabilities
            ID | Time | Balance
            \(liabilityBalances.map { "\($0.key) | \($0.value)" }.joined(separator: "\n"))
            """
        }
    }
}
