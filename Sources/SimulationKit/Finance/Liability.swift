//
//  Ledger.swift
//  
//

import Foundation

// Credit: Increase
// Debit: Decrease
struct Liability: Equatable {
    let id: UInt
    var transactions: [Self.Transaction] = []

    init(
        id: UInt,
        balance: Decimal
    ) {
        self.id = id
        self.transactions = [Transaction(amount: balance)]
    }

    init(
        id: UInt,
        transactions: [Self.Transaction]
    ) {
        self.id = id
        self.transactions = transactions
    }

    func tick(rate: Int) -> Self {
        let gain = currentBalance().decimalizedAdjustment(
            percentage: UInt(rate)
        )
        return self.increased(by: gain)
    }

    func currentBalance() -> Decimal {
        let balance = transactions.map { $0.amount }.reduce(0, +)
        return balance
    }

    enum Transaction: Equatable {
        case credit(amount: Decimal)
        case debit(amount: Decimal)

        var amount: Decimal {
            switch self {
            case .credit(amount: let amount):
                return amount
            case .debit(amount: let amount):
                var negatedAmount = amount
                negatedAmount.negate()
                return negatedAmount
            }
        }

        init(amount: Decimal) {
            if amount.isSignMinus {
                self = .debit(amount: -amount)
            } else {
                self = .credit(amount: amount)
            }
        }

        static func decreasing(by amount: Decimal) -> Self {
            return .debit(amount: amount)
        }

        static func increasing(by amount: Decimal) -> Self {
            return .credit(amount: amount)
        }
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

    func credited(amount: Decimal) -> Self {
        return transacted(
            .credit(amount: amount)
        )
    }

    func debited(amount: Decimal) -> Self {
        return transacted(
            .debit(amount: amount)
        )
    }

    func transacted(_ transaction: Transaction) -> Self {
        return Self(
            id: id,
            transactions: transactions + [transaction]
        )
    }
}
