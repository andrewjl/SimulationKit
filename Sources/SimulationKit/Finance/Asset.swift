//
//  Asset.swift
//  
//

import Foundation

// Credit: Decrease
// Debit: Increase
struct Asset: Equatable {
    let id: UInt
    var transactions: [Self.Transaction] = []

    init(
        id: UInt,
        balance: Decimal
    ) {
        self.id = id
        if balance.isSignMinus {
            self.transactions = [.credit(amount: balance)]
        } else {
            self.transactions = [.debit(amount: balance)]
        }
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
                var negatedAmount = amount
                negatedAmount.negate()
                return negatedAmount
            case .debit(amount: let amount):
                return amount
            }
        }

        static func decreasing(by amount: Decimal) -> Self {
            return .credit(amount: amount)
        }

        static func increasing(by amount: Decimal) -> Self {
            return .debit(amount: amount)
        }
    }
}

extension Asset {
    func decreased(by amount: Decimal) -> Self {
        return self.credited(amount: amount)
    }

    func increased(by amount: Decimal) -> Self {
        return self.debited(amount: amount)
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
            transactions: transactions + [transaction]
        )
    }
}

extension Asset: CustomStringConvertible {
    var description: String {
        return """
            Balance: \(currentBalance())
        """
    }
}
