//
//  Ledger.swift
//  
//

import Foundation

// Credit: Increase
// Debit: Decrease
struct Liability {
    let id: UInt
    let rate: UInt
    var transactions: [Self.Transaction] = []

    init(
        id: UInt,
        rate: UInt,
        balance: Decimal
    ) {
        self.id = id
        self.rate = rate
        if balance.isSignMinus {
            self.transactions = [.debit(amount: balance)]
        } else {
            self.transactions = [.credit(amount: balance)]
        }
    }

    init(
        id: UInt,
        rate: UInt,
        transactions: [Self.Transaction]
    ) {
        self.id = id
        self.rate = rate
        self.transactions = transactions
    }

    func tick() -> Self {
        let gain = currentBalance().decimalizedAdjustment(
            percentage: rate
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
        return transacted(.credit(amount: amount))
    }

    func debited(amount: Decimal) -> Self {
        return transacted(.debit(amount: amount))
    }

    func transacted(_ transaction: Transaction) -> Self {
        return Self(
            id: id,
            rate: rate,
            transactions: transactions + [transaction]
        )
    }
}
