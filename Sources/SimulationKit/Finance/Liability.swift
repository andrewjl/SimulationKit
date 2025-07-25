//
//  Ledger.swift
//  
//

import Foundation

// Credit: Increase
// Debit: Decrease
struct Liability: Equatable {
    let id: String
    let name: String
    var transactions: [Self.Transaction] = []

    init(
        id: String,
        name: String,
        balance: Decimal
    ) {
        self.id = id
        self.name = name
        self.transactions = [Transaction(amount: balance)]
    }

    init(
        id: String,
        name: String,
        transactions: [Self.Transaction]
    ) {
        self.id = id
        self.name = name
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
        name: String = "",
        id: String = UUID().uuidString
    ) -> Self {
        return Self(
            id: id,
            name: name,
            transactions: transactions
        )
    }

    static func make(
        from balance: Decimal,
        name: String = "",
        id: String = UUID().uuidString
    ) -> Self {
        return Self(
            id: id,
            name: name,
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
            name: name,
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

extension Liability: CustomDebugStringConvertible {
    static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currencyAccounting
        formatter.currencyCode = "USD"
        return formatter
    }()

    public var debugDescription: String {
        var result = "|---------\(name)---------|\n"

        let footerCount = result.count - 1

        for transaction in self.transactions {
            let formattedAmount = Self.formatter.string(
                for: transaction.amount
            )!

            let totalPadding = footerCount - 2 - formattedAmount.count
            let trailingPadding = transaction.amount.isSignMinus ? 7 : 8

            if totalPadding.isMultiple(of: 2) {
                let trailingPaddingString = String(
                    repeating: " ",
                    count: trailingPadding
                )
                let paddingString = String(
                    repeating: " ",
                    count: totalPadding - trailingPadding
                )

                result.append(
                    "|\(paddingString)\(formattedAmount)\(trailingPaddingString)|\n"
                )
            } else {
                let trailingPaddingString = String(
                    repeating: " ",
                    count: trailingPadding
                )
                let leadingPadding = totalPadding - trailingPadding
                let leadingPaddingString = String(
                    repeating: " ",
                    count: leadingPadding
                )
                result.append(
                    "|\(leadingPaddingString)\(formattedAmount)\(trailingPaddingString)|\n"
                )
            }
        }

        result.append(
            String(
                "|"
            )
        )
        result.append(
            String(
                repeating: "-",
                count: footerCount-2
            )
        )
        result.append(
            String(
                "|"
            )
        )

        return result
    }
}
