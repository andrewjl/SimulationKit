//
//  AssetTests.swift
//  
//

import XCTest
@testable import SimulationKit

final class AssetTests: XCTestCase {
    func testCreation() throws {
        let asset = Asset(id: 0, balance: 100.0)

        XCTAssertEqual(asset.transactions.count, 1)
        XCTAssertEqual(asset.transactions.first, Asset.Transaction.debit(amount: 100.0))
        XCTAssertEqual(asset.currentBalance(), 100.0)
    }

    func testNegativeBalance() throws {
        let asset = Asset(id: 0, balance: -100.0)

        XCTAssertEqual(asset.transactions.count, 1)
        XCTAssertEqual(asset.transactions.first, Asset.Transaction.credit(amount: 100.0))
        XCTAssertEqual(asset.currentBalance(), -100.0)
    }

    func testTick() throws {
        let asset = Asset(id: 0, balance: 200.0)
        let nextAsset = asset.tick(rate: 5)

        XCTAssertEqual(nextAsset.currentBalance(), 210.0)
    }

    func testCredit() throws {
        let asset = Asset(id: 0, transactions: [.credit(amount: 100.0)])
        XCTAssertEqual(
            asset.currentBalance(),
            -100.0,
            "Initial asset balance should be +100.00"
        )

        let creditedAsset = asset.credited(amount: 20.0)
        XCTAssertEqual(
            creditedAsset.currentBalance(),
            -120.0,
            "Credited asset balance should be +120.00"
        )
    }

    func testDebit() throws {
        let asset = Asset(id: 0, transactions: [.debit(amount: 100.0)])
        XCTAssertEqual(
            asset.currentBalance(),
            100.0,
            "Initial asset balance should be -100.00"
        )

        let creditedAsset = asset.credited(amount: 20.0)
        XCTAssertEqual(
            creditedAsset.currentBalance(),
            80.0,
            "Debited asset balance should be +80.00"
        )

        let debitedAsset = asset.debited(amount: 20.0)
        XCTAssertEqual(
            debitedAsset.currentBalance(),
            120.0,
            "Debited asset balance should be +120.00"
        )
    }

    func testIncrease() throws {
        let asset = Asset(id: 0, balance: 100.0)
        let increasedAsset = asset.increased(by: 20.0)
        XCTAssertEqual(
            increasedAsset.currentBalance(),
            120.0,
            "When increased asset balance should be +120.0"
        )
    }

    func testDecrease() throws {
        let asset = Asset(id: 0, balance: 100.0)
        let decreasedAsset = asset.decreased(by: 20.0)
        XCTAssertEqual(
            decreasedAsset.currentBalance(),
            80.0,
            "When decreased asset balance should be +80.0"
        )
    }

    func testTransactions() throws {
        let increase = Asset.Transaction.increasing(by: 50.0)

        guard case Asset.Transaction.debit(amount: let debitedAmount) = increase else {
            fatalError()
        }
        XCTAssertEqual(
            debitedAmount,
            50.0,
            "Increased asset transaction should be a debit of +50.0"
        )

        let decrease = Asset.Transaction.decreasing(by: 50.0)

        guard case Asset.Transaction.credit(amount: let creditedAmount) = decrease else {
            fatalError()
        }
        XCTAssertEqual(
            creditedAmount,
            50.0,
            "Decreased asset transaction should be a credit of +50.0"
        )
    }

    func testArray() throws {
        var assets = [
            Asset(id: 0, balance: 100.0),
            Asset(id: 1, balance: 50.0),
        ]
        XCTAssertEqual(assets.currentBalance(), 150.0)

        assets = assets.event(.asset(transaction: .debit(amount: 50.0), id: 1, ledgerID: 0))
        XCTAssertEqual(assets.currentBalance(), 200.0)

        assets = assets.event(.asset(transaction: .debit(amount: 50.0), id: 2, ledgerID: 0))
        XCTAssertEqual(assets.currentBalance(), 200.0)
    }
}
