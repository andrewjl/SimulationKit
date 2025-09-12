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

public struct Ledger: Equatable {
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
                equities: equities,
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
        case .createAsset(let name, let accountID):
            return Ledger(
                id: id,
                assets: assets + [
                    Asset(
                        id: accountID,
                        name: name,
                        transactions: []
                    )
                ],
                liabilities: liabilities,
                equities: equities,
                revenues: revenues,
                expenses: expenses,
                generalJournal: updatedGeneralJournal
            )
        case .createLiability(let name, let accountID):
            return Ledger(
                id: id,
                assets: assets,
                liabilities: liabilities + [
                    Liability(
                        id: accountID,
                        name: name,
                        transactions: []
                    )
                ],
                equities: equities,
                revenues: revenues,
                expenses: expenses,
                generalJournal: updatedGeneralJournal
            )
        case .createEquity(let name, let accountID):
            return Ledger(
                id: id,
                assets: assets,
                liabilities: liabilities,
                equities: equities + [
                    Equity(
                        id: accountID,
                        name: name,
                        transactions: []
                    )
                ],
                revenues: revenues,
                expenses: expenses,
                generalJournal: updatedGeneralJournal
            )
        case .createRevenue(let name, let accountID):
            return Ledger(
                id: id,
                assets: assets,
                liabilities: liabilities,
                equities: equities,
                revenues: revenues + [
                    Revenue(
                        id: accountID,
                        name: name,
                        transactions: []
                    )
                ],
                expenses: expenses,
                generalJournal: updatedGeneralJournal
            )
        case .createExpense(let name, let accountID):
            return Ledger(
                id: id,
                assets: assets,
                liabilities: liabilities,
                equities: equities,
                revenues: revenues,
                expenses: expenses + [
                    Expense(
                        id: accountID,
                        name: name,
                        transactions: []
                    )
                ],
                generalJournal: updatedGeneralJournal
            )
        }
    }

    func applying(
        events: [Event],
        at period: UInt32
    ) -> Self {
        var ledger = self

        for event in events {
            ledger = ledger.applying(
                event: event,
                at: period
            )
        }

        return ledger
    }

    public enum Event: Equatable {
        case createAsset(name: String, accountID: String)
        case createLiability(name: String, accountID: String)
        case createEquity(name: String, accountID: String)
        case createRevenue(name: String, accountID: String)
        case createExpense(name: String, accountID: String)
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
            case .createAsset(name: _, accountID: _):
                return .zero
            case .createLiability(name: _, accountID: _):
                return .zero
            case .createEquity(name: _, accountID: _):
                return .zero
            case .createRevenue(name: _, accountID: _):
                return .zero
            case .createExpense(name: _, accountID: _):
                return .zero
            }
        }
    }
}

extension Ledger {
    static func make(
        id: String = UUID().uuidString,
        assets: [Asset] = [],
        liabilities: [Liability] = [],
        equities: [Equity] = [],
        revenues: [Revenue] = [],
        expenses: [Expense] = [],
        at period: UInt32
    ) -> Self {
        let assetEvents: [Capture<Event>] = assets.reduce(into: []) { partialResult, asset in
            partialResult += [
                Capture(
                    entity: Event.createAsset(
                        name: asset.name,
                        accountID: asset.id
                    ),
                    timestamp: period
                )
            ]

            partialResult += asset.transactions.map {
                Capture(
                    entity: Event.postAsset(
                        transaction: $0,
                        accountID: asset.id
                    ),
                    timestamp: period
                )
            }
        }
        
        let liabilityEvents: [Capture<Event>] = liabilities.reduce(into: []) { partialResult, liability in
            partialResult += [
                Capture(
                    entity: Event.createLiability(
                        name: liability.name,
                        accountID: liability.id
                    ),
                    timestamp: period
                )
            ]

            partialResult += liability.transactions.map {
                Capture(
                    entity: Event.postLiability(
                        transaction: $0,
                        accountID: liability.id
                    ),
                    timestamp: period
                )
            }
        }

        let equityEvents: [Capture<Event>] = equities.reduce(into: []) { partialResult, equity in
            partialResult += [
                Capture(
                    entity: Event.createEquity(
                        name: equity.name,
                        accountID: equity.id
                    ),
                    timestamp: period
                )
            ]

            partialResult += equity.transactions.map {
                Capture(
                    entity: Event.postEquity(
                        transaction: $0,
                        accountID: equity.id
                    ),
                    timestamp: period
                )
            }
        }

        let revenueEvents: [Capture<Event>] = revenues.reduce(into: []) { partialResult, revenue in
            partialResult += [
                Capture(
                    entity: Event.createRevenue(
                        name: revenue.name,
                        accountID: revenue.id
                    ),
                    timestamp: period
                )
            ]

            partialResult += revenue.transactions.map {
                Capture(
                    entity: Event.postRevenue(
                        transaction: $0,
                        accountID: revenue.id
                    ),
                    timestamp: period
                )
            }
        }

        let expenseEvents: [Capture<Event>] = expenses.reduce(into: []) { partialResult, expense in
            partialResult += [
                Capture(
                    entity: Event.createExpense(
                        name: expense.name,
                        accountID: expense.id
                    ),
                    timestamp: period
                )
            ]

            partialResult += expense.transactions.map {
                Capture(
                    entity: Event.postExpense(
                        transaction: $0,
                        accountID: expense.id
                    ),
                    timestamp: period
                )
            }
        }

        let generalJournal: [Capture<Event>] = assetEvents + liabilityEvents + equityEvents +
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

