//
//  Ledger.swift
//  
//

import Foundation

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
    var revenues: [Revenue] = []
    var expenses: [Expense] = []

    func currentBalance() -> Decimal {
        let assetSum = assets.map { $0.currentBalance() }.reduce(Decimal.zero, +)
        let liabilitySum = liabilities.map { $0.currentBalance() }.reduce(Decimal.zero, +)
        let equitySum = equities.map { $0.currentBalance() }.reduce(Decimal.zero, +)
        let revenueSum = revenues.map { $0.currentBalance() }.reduce(Decimal.zero, +)
        let expensesSum = expenses.map { $0.currentBalance() }.reduce(Decimal.zero, +)

        return assetSum - liabilitySum - (equitySum + revenueSum - expensesSum)
    }

    func applying(event: Event) -> Self {
        switch event {
        case .asset(let transaction, let accountID):
            return Ledger(
                id: id,
                assets: assets.map { $0.id == accountID ? $0.transacted(transaction) : $0 },
                liabilities: liabilities,
                equities: equities,
                revenues: revenues,
                expenses: expenses
            )
        case .liability(let transaction, let accountID):
            return Ledger(
                id: id,
                assets: assets,
                liabilities: liabilities.map { $0.id == accountID ? $0.transacted(transaction) : $0 },
                equities: equities,
                revenues: revenues,
                expenses: expenses
            )
        case .equity(transaction: let transaction, accountID: let accountID):
            return Ledger(
                id: id,
                assets: assets,
                liabilities: liabilities,
                equities: equities.map { $0.id == accountID ? $0.transacted(transaction) : $0 },
                revenues: revenues,
                expenses: expenses
            )
        case .revenue(transaction: let transaction, accountID: let accountID):
            return Ledger(
                id: id,
                assets: assets,
                liabilities: liabilities,
                revenues: revenues.map { $0.id == accountID ? $0.transacted(transaction) : $0 },
                expenses: expenses
            )
        case .expense(transaction: let transaction, accountID: let accountID):
            return Ledger(
                id: id,
                assets: assets,
                liabilities: liabilities,
                equities: equities,
                revenues: revenues,
                expenses: expenses.map { $0.id == accountID ? $0.transacted(transaction) : $0 }
            )
        }
    }

    func applying(events: [Event]) -> Self {
        var eventedAssets = assets
        var eventedLiabilities = liabilities
        var eventedEquities = equities
        var eventedRevenues = revenues
        var eventedExpenses = expenses

        for event in events {
            switch event {
            case .asset(let transaction, let id):
                eventedAssets = eventedAssets.map { $0.id == id ? $0.transacted(transaction) : $0 }
            case .liability(let transaction, let id):
                eventedLiabilities = eventedLiabilities.map { $0.id == id ? $0.transacted(transaction) : $0 }
            case .equity(transaction: let transaction, accountID: let id):
                eventedEquities = eventedEquities.map { $0.id == id ? $0.transacted(transaction) : $0 }
            case .revenue(transaction: let transaction, accountID: let id):
                eventedRevenues = eventedRevenues.map { $0.id == id ? $0.transacted(transaction) : $0 }
            case .expense(transaction: let transaction, accountID: let id):
                eventedExpenses = eventedExpenses.map { $0.id == id ? $0.transacted(transaction) : $0 }
            }
        }
        
        return Self(
            id: id,
            assets: eventedAssets,
            liabilities: eventedLiabilities,
            equities: eventedEquities,
            revenues: eventedRevenues,
            expenses: eventedExpenses
        )
    }

    enum Event: Equatable {
        case asset(transaction: Asset.Transaction, accountID: String)
        case liability(transaction: Liability.Transaction, accountID: String)
        case equity(transaction: Equity.Transaction, accountID: String)
        case revenue(transaction: Revenue.Transaction, accountID: String)
        case expense(transaction: Expense.Transaction, accountID: String)

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
            case .revenue(
                transaction: let transaction,
                accountID: _
            ):
                return transaction.amount

            case .expense(
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
            case .revenue(
                transaction: _,
                accountID: let id
            ):
                return id
            case .expense(
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
        self.applying(
            events: self.eventsAdjustingAllAssetBalances(by: rate)
        )
    }

    func adjustAllLiabilityBalances(
        by rate: Int
    ) -> Self {
        self.applying(
            events: self.eventsAdjustingAllLiabilityBalances(by: rate)
        )
    }
}

extension Ledger {
    func adding(_ asset: Asset) -> Self {
        return Self(
            id: id,
            assets: assets + [asset],
            liabilities: liabilities,
            equities: equities,
            revenues: revenues,
            expenses: expenses
        )
    }

    func adding(_ liability: Liability) -> Self {
        return Self(
            id: id,
            assets: assets,
            liabilities: liabilities + [liability],
            equities: equities,
            revenues: revenues,
            expenses: expenses
        )
    }

    func adding(_ equity: Equity) -> Self {
        return Self(
            id: id,
            assets: assets,
            liabilities: liabilities,
            equities: equities + [equity],
            revenues: revenues,
            expenses: expenses
        )
    }

    func adding(_ revenue: Revenue) -> Self {
        return Self(
            id: id,
            assets: assets,
            liabilities: liabilities,
            equities: equities,
            revenues: revenues + [revenue],
            expenses: expenses
        )
    }

    func adding(_ expense: Expense) -> Self {
        return Self(
            id: id,
            assets: assets,
            liabilities: liabilities,
            equities: equities,
            revenues: revenues,
            expenses: expenses + [expense]
        )
    }
}

extension Ledger {
    static func make(
        id: String = UUID().uuidString,
        assets: [Asset] = [],
        liabilities: [Liability] = [],
        equities: [Equity] = [],
        revenues: [Revenue] = [],
        expenses: [Expense] = []
    ) -> Self {
        return Self(
            id: id,
            assets: assets,
            liabilities: liabilities,
            equities: equities,
            revenues: revenues,
            expenses: expenses
        )
    }
}
