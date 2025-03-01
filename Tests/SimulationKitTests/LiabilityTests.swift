//
//  LiabilityTests.swift
//  
//

import XCTest
@testable import SimulationKit

final class LiabilityTests: XCTestCase {
    func testCreation() throws {
        let liability = Liability(id: 0, rate: 4, balance: 100.0)

        XCTAssertEqual(liability.transactions.count, 1)
        XCTAssertEqual(liability.transactions.first, Liability.Transaction.credit(amount: 100.0))
        XCTAssertEqual(liability.currentBalance(), 100.0)
    }

    func testTick() throws {
        let asset = Liability(id: 0, rate: 5, balance: 200.0)
        let nextAsset = asset.tick()

        XCTAssertEqual(nextAsset.currentBalance(), 210.0)
    }

    func testCredit() throws {
        let liability = Liability(id: 0, rate: 5, transactions: [.credit(amount: 100.0)])
        XCTAssertEqual(
            liability.currentBalance(),
            100.0,
            "Initial liability balance should be +100.00"
        )

        let creditedLiability = liability.credited(amount: 20.0)
        XCTAssertEqual(
            creditedLiability.currentBalance(),
            120.0,
            "Credited liability balance should be +120.00"
        )
    }

    func testDebit() throws {
        let liability = Liability(id: 0, rate: 5, transactions: [.debit(amount: 100.0)])
        XCTAssertEqual(
            liability.currentBalance(),
            -100.0,
            "Initial liability balance should be -100.00"
        )

        let creditedLiability = liability.credited(amount: 20.0)
        XCTAssertEqual(
            creditedLiability.currentBalance(),
            -80.0,
            "Debited liability balance should be +80.00"
        )

        let debitedLiability = liability.debited(amount: 20.0)
        XCTAssertEqual(
            debitedLiability.currentBalance(),
            -120.0,
            "Debited liability balance should be +120.00"
        )
    }

    func testIncrease() throws {
        let liability = Liability(id: 0, rate: 5, balance: 100.0)
        let increasedLiability = liability.increased(by: 20.0)
        XCTAssertEqual(
            increasedLiability.currentBalance(),
            120.0,
            "When increased liability balance should be +120.0"
        )
    }

    func testDecrease() throws {
        let liability = Liability(id: 0, rate: 5, balance: 100.0)
        let decreasedLiability = liability.decreased(by: 20.0)
        XCTAssertEqual(
            decreasedLiability.currentBalance(),
            80.0,
            "When decreased liability balance should be +80.0"
        )
    }

    func testTransactions() throws {
        let increase = Liability.Transaction.increasing(by: 50.0)

        guard case Liability.Transaction.credit(amount: let creditedAmount) = increase else {
            fatalError()
        }
        XCTAssertEqual(
            creditedAmount,
            50.0,
            "Increased liability transaction should be a credit of +50.0"
        )

        let decrease = Liability.Transaction.decreasing(by: 50.0)

        guard case Liability.Transaction.debit(amount: let debitedAmount) = decrease else {
            fatalError()
        }
        XCTAssertEqual(
            debitedAmount,
            50.0,
            "Decreased liability transaction should be a debit of +50.0"
        )
    }

    func testArray() throws {
        var liabilities = [
            Liability(id: 0, rate: 5, balance: 100.0),
            Liability(id: 1, rate: 5, balance: 50.0),
        ]

        XCTAssertEqual(liabilities.currentBalance(), 150.0)

        liabilities = liabilities.event(.liability(transaction: .credit(amount: 50.0), id: 1))
        XCTAssertEqual(liabilities.currentBalance(), 200.0)

        liabilities = liabilities.event(.liability(transaction: .credit(amount: 50.0), id: 2))
        XCTAssertEqual(liabilities.currentBalance(), 200.0)
    }
}

