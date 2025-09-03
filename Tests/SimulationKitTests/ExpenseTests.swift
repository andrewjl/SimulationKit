//
//  ExpenseTests.swift
//  SimulationKit
//

import XCTest
@testable import SimulationKit

final class ExpenseTests: XCTestCase {
    func testPositiveStartingBalance() throws {
        let expense = Expense(
            id: "1",
            name: "",
            balance: 100.0
        )

        XCTAssertEqual(
            expense.transactions.count,
            1
        )

        let firstTransaction = try XCTUnwrap(
            expense.transactions.first
        )

        XCTAssertTrue(
            firstTransaction.isDebit
        )

        XCTAssertFalse(
            firstTransaction.isCredit
        )

        XCTAssertEqual(
            firstTransaction.amount,
            100.0
        )
    }

    func testNegativeStartingBalance() throws {
        let expense = Expense(
            id: "1",
            name: "",
            balance: -100.0
        )

        XCTAssertEqual(
            expense.transactions.count,
            1
        )

        let firstTransaction = try XCTUnwrap(
            expense.transactions.first
        )

        XCTAssertTrue(
            firstTransaction.isCredit
        )

        XCTAssertFalse(
            firstTransaction.isDebit
        )

        XCTAssertEqual(
            firstTransaction.amount,
            -100.0
        )
    }

    func testCredit() throws {
        var expense = Expense(
            id: "1",
            name: "",
            transactions: [
                .credited(by: 100.0)
            ]
        )

        XCTAssertEqual(
            expense.currentBalance(),
            -100.0,
        )

        expense = expense.credited(by: 20.0)

        XCTAssertEqual(
            expense.currentBalance(),
            -120.0
        )
    }

    func testDebit() throws {
        var expense = Expense(
            id: "1",
            name: "",
            transactions: [
                .debited(by: 100.0)
            ]
        )

        XCTAssertEqual(
            expense.currentBalance(),
            100.0,
        )

        expense = expense.debited(by: 20.0)

        XCTAssertEqual(
            expense.currentBalance(),
            120.0
        )
    }

    func testIncrease() throws {
        var expense = Expense(
            id: "1",
            name: "",
            balance: 100.0
        )

        expense = expense.increased(by: 20.0)

        XCTAssertEqual(
            expense.currentBalance(),
            120.0
        )
    }

    func testDecrease() throws {
        var expense = Expense(
            id: "1",
            name: "",
            balance: 100.0
        )

        expense = expense.decreased(by: 20.0)

        XCTAssertEqual(
            expense.currentBalance(),
            80.0
        )
    }

    func testTransactions() throws {
        let increase = Expense.Transaction.increasing(by: 50.0)

        guard case Expense.Transaction.debit(
            id: _,
            amount: let debitedAmount
        ) = increase else {
            fatalError()
        }
        XCTAssertEqual(
            debitedAmount,
            50.0
        )

        let decrease = Expense.Transaction.decreasing(by: 50.0)

        guard case Expense.Transaction.credit(
            id: _,
            amount: let creditedAmount
        ) = decrease else {
            fatalError()
        }
        XCTAssertEqual(
            creditedAmount,
            50.0
        )
    }

    func testDebugDescription() throws {
        var expense = Expense(
            id: "1",
            name: "Expense",
            balance: 1.0
        )

        expense = expense.increased(by: 17)
        expense = expense.decreased(by: 11.5)
        expense = expense.increased(by: 101.75)
        expense = expense.increased(by: 1_101.0)
        expense = expense.increased(by: 11_101.0)
        expense = expense.increased(by: 111_101.0)
        expense = expense.decreased(by: 1_111_101.0)

        XCTAssertEqual(
            expense.debugDescription,
            """
|---------Expense---------|
|            $1.00        |
|           $17.00        |
|          ($11.50)       |
|          $101.75        |
|        $1,101.00        |
|       $11,101.00        |
|      $111,101.00        |
|   ($1,111,101.00)       |
|-------------------------|
"""
        )
    }
}
