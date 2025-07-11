//
//  Ledger.swift
//  
//

import Foundation

// Credit: Increase
// Debit: Decrease
struct Liability: Equatable {
    static var autoincrementedID: UInt = 0

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
    static func make(from transactions: [Transaction]) -> Self {
        defer {
            Self.autoincrementedID += 1
        }
        return Self(
            id: Self.autoincrementedID,
            transactions: transactions
        )
    }

    static func make(from balance: Decimal) -> Self {
        defer {
            Self.autoincrementedID += 1
        }
        return Self(
            id: Self.autoincrementedID,
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

extension Liability {
    func adjusted(by percentageRate: Int) -> Self {
        return self.transacted(
            self.adjustmentTransaction(by: percentageRate)
        )
    }

    func adjustmentTransaction(by percentageRate: Int) -> Self.Transaction {
        let adjustmentAmount = currentBalance().decimalizedAdjustment(percentage: percentageRate)
        return Transaction(
            amount: adjustmentAmount
        )
    }
}
