//
//  RevenueTests.swift
//  SimulationKit
//

import XCTest
@testable import SimulationKit

final class RevenueTests: XCTestCase {
    func testPositiveStartingBalance() throws {
        let revenue = Revenue(
            id: "1",
            name: "",
            balance: 100.0
        )

        XCTAssertEqual(
            revenue.transactions.count,
            1
        )

        let firstTransaction = try XCTUnwrap(
            revenue.transactions.first
        )

        XCTAssertTrue(
            firstTransaction.isCredit
        )

        XCTAssertFalse(
            firstTransaction.isDebit
        )

        XCTAssertEqual(
            firstTransaction.amount,
            100.0
        )
    }

    func testNegativeStartingBalance() throws {
        let revenue = Revenue(
            id: "1",
            name: "",
            balance: -100.0
        )

        XCTAssertEqual(
            revenue.transactions.count,
            1
        )

        let firstTransaction = try XCTUnwrap(
            revenue.transactions.first
        )

        XCTAssertTrue(
            firstTransaction.isDebit
        )

        XCTAssertFalse(
            firstTransaction.isCredit
        )

        XCTAssertEqual(
            firstTransaction.amount,
            -100.0
        )
    }

    func testCredit() throws {
        var revenue = Revenue(
            id: "1",
            name: "",
            transactions: [
                .credited(by: 100.0)
            ]
        )

        XCTAssertEqual(
            revenue.currentBalance(),
            100.0,
        )

        revenue = revenue.credited(by: 20.0)

        XCTAssertEqual(
            revenue.currentBalance(),
            120.0
        )
    }

    func testDebit() throws {
        var revenue = Revenue(
            id: "1",
            name: "",
            transactions: [
                .credited(by: 100.0)
            ]
        )

        XCTAssertEqual(
            revenue.currentBalance(),
            100.0,
        )

        revenue = revenue.debited(by: 20.0)

        XCTAssertEqual(
            revenue.currentBalance(),
            80.0
        )
    }

    func testIncrease() throws {
        var revenue = Revenue(
            id: "1",
            name: "",
            balance: 100.0
        )

        revenue = revenue.increased(by: 20.0)

        XCTAssertEqual(
            revenue.currentBalance(),
            120.0
        )
    }

    func testDecrease() throws {
        var revenue = Revenue(
            id: "1",
            name: "",
            balance: 100.0
        )

        revenue = revenue.decreased(by: 20.0)

        XCTAssertEqual(
            revenue.currentBalance(),
            80.0
        )
    }

    func testTransactions() throws {
        let increase = Revenue.Transaction.increasing(
            by: 50.0
        )

        guard case Revenue.Transaction.credit(
            id: _,
            amount: let creditedAmount
        ) = increase else {
            XCTFail()
            fatalError()
        }

        XCTAssertEqual(
            creditedAmount,
            50.0
        )

        let decrease = Revenue.Transaction.decreasing(
            by: 50.0
        )

        guard case Revenue.Transaction.debit(
            id: _,
            amount: let debitedAmount
        ) = decrease else {
            XCTFail()
            fatalError()
        }

        XCTAssertEqual(
            debitedAmount,
            50.0
        )
    }

    func testDebugDescription() throws {
        var revenue = Revenue(
            id: "1",
            name: "Revenue",
            balance: 1.0
        )

        revenue = revenue.increased(by: 17)
        revenue = revenue.decreased(by: 11.5)
        revenue = revenue.increased(by: 101.75)
        revenue = revenue.increased(by: 1_101.0)
        revenue = revenue.increased(by: 11_101.0)
        revenue = revenue.increased(by: 111_101.0)
        revenue = revenue.decreased(by: 1_111_101.0)

        XCTAssertEqual(
            revenue.debugDescription,
            """
|---------Revenue---------|
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
