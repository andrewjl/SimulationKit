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
        guard case Ledger.Event.asset(transaction: let transaction, id: let id, ledgerID: _) = event else {
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
        guard case Ledger.Event.liability(transaction: let transaction, id: let id, ledgerID: _) = event else {
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
            guard case let Ledger.Event.asset(transaction: _, id: id, ledgerID: _) = $0 else {
                return false
            }

            return assetID == id
        })
    }

    func event(liabilityID: UInt) -> Ledger.Event? {
        self.first(where: {
            guard case let Ledger.Event.liability(transaction: _, id: id, ledgerID: _) = $0 else {
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

struct Ledger {
    static var autoincrementedID: UInt = 0

    var id: UInt
    var assets: [Asset]
    var liabilities: [Liability]

    func currentBalance() -> Decimal {
        let assetSum = assets.map { $0.currentBalance() }.reduce(Decimal.zero, +)
        let liabilitySum = liabilities.map { $0.currentBalance() }.reduce(Decimal.zero, +)

        return assetSum - liabilitySum
    }

    func tick(event: Event) -> Self {
        switch event {
        case .asset(let transaction, let id, _):
            return Ledger(
                id: id,
                assets: assets.map { $0.id == id ? $0.transacted(transaction) : $0 },
                liabilities: liabilities
            )
        case .liability(let transaction, let id, _):
            return Ledger(
                id: id,
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
            case .asset(let transaction, let id, _):
                eventedAssets = eventedAssets.map { $0.id == id ? $0.transacted(transaction) : $0 }
            case .liability(let transaction, let id, _):
                eventedLiabilities = eventedLiabilities.map { $0.id == id ? $0.transacted(transaction) : $0 }
            }
        }
        
        return Self(
            id: id,
            assets: eventedAssets,
            liabilities: eventedLiabilities
        )
    }

    func asPoints(tick: Tick) -> Points {
        let assetBalances: [UInt: Decimal] = Dictionary(uniqueKeysWithValues: assets.map { ($0.id, $0.currentBalance()) })
        let liabilityBalances = Dictionary(uniqueKeysWithValues: liabilities.map { ($0.id, $0.currentBalance()) })
        let timestamp = tick.time

        return Points(
            assetBalances: assetBalances,
            liabilityBalances: liabilityBalances,
            timestamp: timestamp
        )
    }

    enum Event {
        case asset(transaction: Asset.Transaction, id: UInt, ledgerID: UInt)
        case liability(transaction: Liability.Transaction, id: UInt, ledgerID: UInt)

        var ledgerID: UInt {
            switch self {
                case .asset(_, _, let ledgerID):
                    return ledgerID
                case .liability(_, _, let ledgerID):
                    return ledgerID
            }
        }
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

extension Ledger {
    struct Points: CustomStringConvertible {
        let assetBalances: [UInt: Decimal]
        let liabilityBalances: [UInt: Decimal]

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
