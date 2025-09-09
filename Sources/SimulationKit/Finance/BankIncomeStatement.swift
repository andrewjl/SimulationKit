//
//  BankIncomeStatement.swift
//  SimulationKit
//

import Foundation

struct BankIncomeStatement: Equatable {
    let totalRevenue: Decimal
    let totalExpenses: Decimal

    init(
        previousLedger: Ledger,
        currentLedger: Ledger
    ) throws {
        guard let previousInterestIncomeAccount = previousLedger
            .revenues
            .first(where: { $0.name == Bank.interestIncomeAccountName }) else {
            throw Error(
                description: "No interest income account in previous ledger"
            )
        }

        guard let currentInterestIncomeAccount = currentLedger
            .revenues
            .first(where: { $0.name == Bank.interestIncomeAccountName }) else {
            throw Error(
                description: "No interest income account in current ledger"
            )
        }

        guard let previousInterestExpensesAccount = previousLedger
            .expenses
            .first(where: { $0.name == Bank.interestExpensesAccountName }) else {
            throw Error(
                description: "No interest expense account in previous ledger"
            )
        }

        guard let currentInterestExpensesAccount = currentLedger
            .expenses
            .first(where: { $0.name == Bank.interestExpensesAccountName }) else {
            throw Error(
                description: "No interest expense account in current ledger"
            )
        }

        self.totalRevenue = currentInterestIncomeAccount.currentBalance() - previousInterestIncomeAccount.currentBalance()
        self.totalExpenses = currentInterestExpensesAccount.currentBalance() - previousInterestExpensesAccount.currentBalance()
    }

    struct Error: Swift.Error, CustomStringConvertible {
        var description: String
    }
}

