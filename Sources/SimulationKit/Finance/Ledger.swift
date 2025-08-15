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

    var generalJournal: [Capture<Event>]

    func currentBalance() -> Decimal {
        let assetSum = assets.map { $0.currentBalance() }.reduce(Decimal.zero, +)
        let liabilitySum = liabilities.map { $0.currentBalance() }.reduce(Decimal.zero, +)
        let equitySum = equities.map { $0.currentBalance() }.reduce(Decimal.zero, +)
        let revenueSum = revenues.map { $0.currentBalance() }.reduce(Decimal.zero, +)
        let expensesSum = expenses.map { $0.currentBalance() }.reduce(Decimal.zero, +)

        return assetSum - liabilitySum - (equitySum + revenueSum - expensesSum)
    }

    func applying(
        event: Event,
        at period: UInt32
    ) -> Self {
        let updatedGeneralJournal = generalJournal + [
            Capture(
                entity: event,
                timestamp: period
            )
        ]

        switch event {
        case .asset(let transaction, let accountID):
            return Ledger(
                id: id,
                assets: assets.map { $0.id == accountID ? $0.transacted(transaction) : $0 },
                liabilities: liabilities,
                equities: equities,
                revenues: revenues,
                expenses: expenses,
                generalJournal: updatedGeneralJournal
            )
        case .liability(let transaction, let accountID):
            return Ledger(
                id: id,
                assets: assets,
                liabilities: liabilities.map { $0.id == accountID ? $0.transacted(transaction) : $0 },
                equities: equities,
                revenues: revenues,
                expenses: expenses,
                generalJournal: updatedGeneralJournal
            )
        case .equity(transaction: let transaction, accountID: let accountID):
            return Ledger(
                id: id,
                assets: assets,
                liabilities: liabilities,
                equities: equities.map { $0.id == accountID ? $0.transacted(transaction) : $0 },
                revenues: revenues,
                expenses: expenses,
                generalJournal: updatedGeneralJournal
            )
        case .revenue(transaction: let transaction, accountID: let accountID):
            return Ledger(
                id: id,
                assets: assets,
                liabilities: liabilities,
                revenues: revenues.map { $0.id == accountID ? $0.transacted(transaction) : $0 },
                expenses: expenses,
                generalJournal: updatedGeneralJournal
            )
        case .expense(transaction: let transaction, accountID: let accountID):
            return Ledger(
                id: id,
                assets: assets,
                liabilities: liabilities,
                equities: equities,
                revenues: revenues,
                expenses: expenses.map { $0.id == accountID ? $0.transacted(transaction) : $0 },
                generalJournal: updatedGeneralJournal
            )
        }
    }

    func applying(
        events: [Event],
        at period: UInt32
    ) -> Self {
        var updatedAssets = assets
        var uodatedLiabilities = liabilities
        var updatedEquities = equities
        var updatedRevenues = revenues
        var updatedExpenses = expenses

        var updatedGeneralJournal = generalJournal

        for event in events {
            updatedGeneralJournal.append(
                Capture(
                    entity: event,
                    timestamp: period
                )
            )

            switch event {
            case .asset(let transaction, let id):
                updatedAssets = updatedAssets.map { $0.id == id ? $0.transacted(transaction) : $0 }
            case .liability(let transaction, let id):
                uodatedLiabilities = uodatedLiabilities.map { $0.id == id ? $0.transacted(transaction) : $0 }
            case .equity(transaction: let transaction, accountID: let id):
                updatedEquities = updatedEquities.map { $0.id == id ? $0.transacted(transaction) : $0 }
            case .revenue(transaction: let transaction, accountID: let id):
                updatedRevenues = updatedRevenues.map { $0.id == id ? $0.transacted(transaction) : $0 }
            case .expense(transaction: let transaction, accountID: let id):
                updatedExpenses = updatedExpenses.map { $0.id == id ? $0.transacted(transaction) : $0 }
            }
        }
        
        return Self(
            id: id,
            assets: updatedAssets,
            liabilities: uodatedLiabilities,
            equities: updatedEquities,
            revenues: updatedRevenues,
            expenses: updatedExpenses,
            generalJournal: generalJournal
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
        by rate: Int,
        at period: UInt32
    ) -> Self {
        self.applying(
            events: self.eventsAdjustingAllAssetBalances(by: rate),
            at: period
        )
    }

    func adjustAllLiabilityBalances(
        by rate: Int,
        at period: UInt32
    ) -> Self {
        self.applying(
            events: self.eventsAdjustingAllLiabilityBalances(by: rate),
            at: period
        )
    }
}

extension Ledger {
    func adding(
        _ asset: Asset,
        at period: UInt32
    ) -> Self {
        return Self(
            id: id,
            assets: assets + [asset],
            liabilities: liabilities,
            equities: equities,
            revenues: revenues,
            expenses: expenses,
            generalJournal: generalJournal + asset.transactions.map {
                Capture(
                    entity: .asset(
                        transaction: $0,
                        accountID: asset.id
                    ),
                    timestamp: period
                )
            }
        )
    }

    func adding(
        _ liability: Liability,
        at period: UInt32
    ) -> Self {
        return Self(
            id: id,
            assets: assets,
            liabilities: liabilities + [liability],
            equities: equities,
            revenues: revenues,
            expenses: expenses,
            generalJournal: generalJournal + liability.transactions.map {
                Capture(
                    entity: .liability(
                        transaction: $0,
                        accountID: liability.id
                    ),
                    timestamp: period
                )
            }
        )
    }

    func adding(
        _ equity: Equity,
        at period: UInt32
    ) -> Self {
        return Self(
            id: id,
            assets: assets,
            liabilities: liabilities,
            equities: equities + [equity],
            revenues: revenues,
            expenses: expenses,
            generalJournal: generalJournal + equity.transactions.map {
                Capture(
                    entity: .equity(
                        transaction: $0,
                        accountID: equity.id
                    ),
                    timestamp: period
                )
            }
        )
    }

    func adding(
        _ revenue: Revenue,
        at period: UInt32
    ) -> Self {
        return Self(
            id: id,
            assets: assets,
            liabilities: liabilities,
            equities: equities,
            revenues: revenues + [revenue],
            expenses: expenses,
            generalJournal: generalJournal + revenue.transactions.map {
                Capture(
                    entity: .revenue(
                        transaction: $0,
                        accountID: revenue.id
                    ),
                    timestamp: period
                )
            }
        )
    }

    func adding(
        _ expense: Expense,
        at period: UInt32
    ) -> Self {
        return Self(
            id: id,
            assets: assets,
            liabilities: liabilities,
            equities: equities,
            revenues: revenues,
            expenses: expenses + [expense],
            generalJournal: generalJournal + expense.transactions.map {
                Capture(
                    entity: .expense(
                        transaction: $0,
                        accountID: expense.id
                    ),
                    timestamp: period
                )
            }
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
        let assetEvents = assets.reduce(into: []) { partialResult, asset in
            partialResult += asset.transactions.map {
                Capture(
                    entity: Event.asset(
                        transaction: $0,
                        accountID: asset.id
                    ),
                    timestamp: 0
                )
            }
        }
        let liabilityEvents = liabilities.reduce(into: []) { partialResult, liability in
            partialResult += liability.transactions.map {
                Capture(
                    entity: Event.liability(
                        transaction: $0,
                        accountID: liability.id
                    ),
                    timestamp: 0
                )
            }
        }
        let equityEvents = equities.reduce(into: []) { partialResult, equity in
            partialResult += equity.transactions.map {
                Capture(
                    entity: Event.equity(
                        transaction: $0,
                        accountID: equity.id
                    ),
                    timestamp: 0
                )
            }
        }

        let revenueEvents = revenues.reduce(into: []) { partialResult, revenue in
            partialResult += revenue.transactions.map {
                Capture(
                    entity: Event.revenue(
                        transaction: $0,
                        accountID: revenue.id
                    ),
                    timestamp: 0
                )
            }
        }

        let expenseEvents = expenses.reduce(into: []) { partialResult, expense in
            partialResult += expense.transactions.map {
                Capture(
                    entity: Event.expense(
                        transaction: $0,
                        accountID: expense.id
                    ),
                    timestamp: 0
                )
            }
        }

        let generalJournal = assetEvents + liabilityEvents + equityEvents +
        revenueEvents + expenseEvents

        return Self(
            id: id,
            assets: assets,
            liabilities: liabilities,
            equities: equities,
            revenues: revenues,
            expenses: expenses,
            generalJournal: generalJournal
        )
    }
}

