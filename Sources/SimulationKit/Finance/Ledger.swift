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
        case .postAsset(let transaction, let accountID):
            return Ledger(
                id: id,
                assets: assets.map { $0.id == accountID ? $0.transacted(transaction) : $0 },
                liabilities: liabilities,
                equities: equities,
                revenues: revenues,
                expenses: expenses,
                generalJournal: updatedGeneralJournal
            )
        case .postLiability(let transaction, let accountID):
            return Ledger(
                id: id,
                assets: assets,
                liabilities: liabilities.map { $0.id == accountID ? $0.transacted(transaction) : $0 },
                equities: equities,
                revenues: revenues,
                expenses: expenses,
                generalJournal: updatedGeneralJournal
            )
        case .postEquity(transaction: let transaction, accountID: let accountID):
            return Ledger(
                id: id,
                assets: assets,
                liabilities: liabilities,
                equities: equities.map { $0.id == accountID ? $0.transacted(transaction) : $0 },
                revenues: revenues,
                expenses: expenses,
                generalJournal: updatedGeneralJournal
            )
        case .postRevenue(transaction: let transaction, accountID: let accountID):
            return Ledger(
                id: id,
                assets: assets,
                liabilities: liabilities,
                revenues: revenues.map { $0.id == accountID ? $0.transacted(transaction) : $0 },
                expenses: expenses,
                generalJournal: updatedGeneralJournal
            )
        case .postExpense(transaction: let transaction, accountID: let accountID):
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
            case .postAsset(let transaction, let id):
                updatedAssets = updatedAssets.map { $0.id == id ? $0.transacted(transaction) : $0 }
            case .postLiability(let transaction, let id):
                uodatedLiabilities = uodatedLiabilities.map { $0.id == id ? $0.transacted(transaction) : $0 }
            case .postEquity(transaction: let transaction, accountID: let id):
                updatedEquities = updatedEquities.map { $0.id == id ? $0.transacted(transaction) : $0 }
            case .postRevenue(transaction: let transaction, accountID: let id):
                updatedRevenues = updatedRevenues.map { $0.id == id ? $0.transacted(transaction) : $0 }
            case .postExpense(transaction: let transaction, accountID: let id):
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
        case postAsset(transaction: Asset.Transaction, accountID: String)
        case postLiability(transaction: Liability.Transaction, accountID: String)
        case postEquity(transaction: Equity.Transaction, accountID: String)
        case postRevenue(transaction: Revenue.Transaction, accountID: String)
        case postExpense(transaction: Expense.Transaction, accountID: String)

        var amount: Decimal {
            switch self {
            case .postAsset(
                transaction: let transaction,
                accountID: _
            ):
                return transaction.amount
            case .postLiability(
                transaction: let transaction,
                accountID: _
            ):
                return transaction.amount
            case .postEquity(
                transaction: let transaction,
                accountID: _
            ):
                return transaction.amount
            case .postRevenue(
                transaction: let transaction,
                accountID: _
            ):
                return transaction.amount

            case .postExpense(
                transaction: let transaction,
                accountID: _
            ):
                return transaction.amount
            }
        }

        var id: String {
            switch self {
            case .postAsset(
                transaction: _,
                accountID: let id
            ):
                return id
            case .postLiability(
                transaction: _,
                accountID: let id
            ):
                return id
            case .postEquity(
                transaction: _,
                accountID: let id
            ):
                return id
            case .postRevenue(
                transaction: _,
                accountID: let id
            ):
                return id
            case .postExpense(
                transaction: _,
                accountID: let id
            ):
                return id
            }
        }
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
                    entity: .postAsset(
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
                    entity: .postLiability(
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
                    entity: .postEquity(
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
                    entity: .postRevenue(
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
                    entity: .postExpense(
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
                    entity: Event.postAsset(
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
                    entity: Event.postLiability(
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
                    entity: Event.postEquity(
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
                    entity: Event.postRevenue(
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
                    entity: Event.postExpense(
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

