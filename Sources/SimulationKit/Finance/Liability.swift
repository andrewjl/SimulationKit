//
//  Ledger.swift
//  
//

import Foundation

// Credit: Increase
// Debit: Decrease
struct Liability: Equatable {
    let id: String
    var transactions: [Self.Transaction] = []

    init(
        id: String,
        balance: Decimal
    ) {
        self.id = id
        self.transactions = [Transaction(amount: balance)]
    }

    init(
        id: String,
        transactions: [Self.Transaction]
    ) {
        self.id = id
        self.transactions = transactions
    }

    func currentBalance() -> Decimal {
        let balance = transactions.map { $0.amount }.reduce(0, +)
        return balance
    }

    enum Transaction: Equatable {
        case credit(id: String, amount: Decimal)
        case debit(id: String, amount: Decimal)

        var amount: Decimal {
            switch self {
            case .credit(id: _, amount: let amount):
                return amount
            case .debit(id: _, amount: let amount):
                var negatedAmount = amount
                negatedAmount.negate()
                return negatedAmount
            }
        }

        init(
            id: String = UUID().uuidString,
            amount: Decimal
        ) {
            if amount.isSignMinus {
                self = .debit(
                    id: id,
                    amount: -amount
                )
            } else {
                self = .credit(
                    id: id,
                    amount: amount
                )
            }
        }

        static func decreasing(
            by amount: Decimal
        ) -> Self {
            return .init(amount: -amount)
        }

        static func increasing(
            by amount: Decimal
        ) -> Self {
            return .init(amount: amount)
        }

        static func credited(
            by amount: Decimal,
            id: String = UUID().uuidString
        ) -> Self {
            return .init(amount: amount)
        }

        static func debited(
            by amount: Decimal,
            id: String = UUID().uuidString
        ) -> Self {
            return .init(amount: -amount)
        }
    }
}

extension Liability {
    static func make(
        from transactions: [Transaction],
        id: String = UUID().uuidString
    ) -> Self {
        return Self(
            id: id,
            transactions: transactions
        )
    }

    static func make(
        from balance: Decimal,
        id: String = UUID().uuidString
    ) -> Self {
        return Self(
            id: id,
            balance: balance
        )
    }
}

extension Liability {
    func decreased(by amount: Decimal) -> Self {
        return transacted(
            Transaction.decreasing(by: amount)
        )
    }

    func increased(by amount: Decimal) -> Self {
        return transacted(
            Transaction.increasing(by: amount)
        )
    }

    func credited(by amount: Decimal) -> Self {
        return transacted(
            Transaction.credited(by: amount)
        )
    }

    func debited(by amount: Decimal) -> Self {
        return transacted(
            Transaction.debited(by: amount)
        )
    }

    func transacted(_ transaction: Transaction) -> Self {
        return Self(
            id: id,
            transactions: transactions + [transaction]
        )
    }
}

extension Liability {
    func adjustmentTransaction(by percentageRate: Int) -> Self.Transaction {
        let adjustmentAmount = currentBalance().decimalizedAdjustment(percentage: percentageRate)
        return Transaction(
            amount: adjustmentAmount
        )
    }
}
