//
//  Asset.swift
//  
//

import Foundation

// Credit: Decrease
// Debit: Increase
struct Asset: Equatable {
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
                var negatedAmount = amount
                negatedAmount.negate()
                return negatedAmount
            case .debit(amount: let amount):
                return amount
            }
        }

        init(amount: Decimal) {
            if amount.isSignMinus {
                self = .credit(amount: -amount)
            } else {
                self = .debit(amount: amount)
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

extension Asset {
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

extension Asset: CustomStringConvertible {
    var description: String {
        return """
            Balance: \(currentBalance())
        """
    }
}
