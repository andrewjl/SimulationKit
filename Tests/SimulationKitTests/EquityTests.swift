//
//  EquityTests.swift
//  SimulationKit
//

import XCTest
@testable import SimulationKit

final class EquityTests: XCTestCase {
    func testCreation() throws {
        let equity = Equity.make(
            from: 100.0,
            name: ""
        )

        XCTAssertEqual(
            equity.transactions.count,
            1
        )
        XCTAssertEqual(
            equity.transactions.first?.amount,
            100.0
        )
        XCTAssertEqual(
            equity.currentBalance(),
            100.0
        )
    }

    func testNegativeBalance() throws {
        let equity = Equity.make(
            from: -100.0,
            name: ""
        )

        XCTAssertEqual(
            equity.transactions.count,
            1
        )
        XCTAssertEqual(
            equity.transactions.first?.amount,
            -100
        )
        XCTAssertEqual(
            equity.currentBalance(),
            -100.0
        )
    }

    func testConvenienceMethods() throws {
        let equity = Equity.make(
            from: [],
            name: ""
        ).credited(
            by: 150.0
        ).debited(
            by: 50.0
        )

        XCTAssertEqual(
            equity.currentBalance(),
            100.0
        )

        XCTAssertEqual(
            equity.transactions.count,
            2
        )
    }

    func testCredit() throws {
        var equity = Equity.make(
            from: .zero,
            name: ""
        )

        equity = equity.transacted(
            .credited(by: 100.0)
        )

        XCTAssertEqual(
            equity.transactions.count,
            2
        )
        XCTAssertEqual(
            equity.transactions.last?.amount,
            100.0
        )
        XCTAssertEqual(
            equity.currentBalance(),
            100.0
        )
    }

    func testDebit() throws {
        var equity = Equity.make(
            from: 100.0,
            name: ""
        )

        let transaction = Equity.Transaction.debited(by: 25)

        XCTAssertEqual(
            transaction.amount,
            -25.0
        )

        equity = equity.transacted(
            transaction
        )

        XCTAssertEqual(
            equity.transactions.count,
            2
        )
        XCTAssertEqual(
            equity.transactions.last?.amount.magnitude,
            25.0
        )
        XCTAssertEqual(
            equity.currentBalance(),
            75.0
        )
    }

    func testDebugDescription() throws {
        var equity = Equity.make(
            from: 100.0,
            name: "Equity"
        )

        equity = equity.increased(by: 12)
        equity = equity.decreased(by: 8.5)
        equity = equity.increased(by: 100.75)
        equity = equity.increased(by: 30000.5)

        XCTAssertEqual(
            equity.debugDescription,
            """
|---------Equity---------|
|         $100.00        |
|          $12.00        |
|          ($8.50)       |
|         $100.75        |
|      $30,000.50        |
|------------------------|
"""
        )
    }
}

