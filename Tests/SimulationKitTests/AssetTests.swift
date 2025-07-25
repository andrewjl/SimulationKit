//
//  AssetTests.swift
//  
//

import XCTest
@testable import SimulationKit

final class AssetTests: XCTestCase {
    func testPositiveStartingBalance() throws {
        let asset = Asset.make(
            from: 100.0,
            name: ""
        )

        XCTAssertEqual(asset.transactions.count, 1)

        guard let firstTransaction = try? XCTUnwrap(
            asset.transactions.first,
            "No transactions in asset"
        ) else {
            XCTFail("No transactions in asset")
            return
        }

        XCTAssertTrue(
            firstTransaction.isDebit
        )

        XCTAssertEqual(
            firstTransaction.amount,
            100.0
        )

        XCTAssertEqual(asset.currentBalance(), 100.0)
    }

    func testNegativeStartingBalance() throws {
        let asset = Asset.make(
            from: -100.0,
            name: ""
        )

        XCTAssertEqual(asset.transactions.count, 1)

        guard let firstTransaction = try? XCTUnwrap(
            asset.transactions.first,
            "No transactions in asset"
        ) else {
            XCTFail("No transactions in asset")
            return
        }

        XCTAssertTrue(
            firstTransaction.isCredit
        )

        XCTAssertEqual(
            firstTransaction.amount,
            -100.0
        )

        XCTAssertEqual(asset.currentBalance(), -100.0)
    }

    func testCredit() throws {
        let asset = Asset.make(
            from: [
                Asset.Transaction.credited(by: 100.0)
            ],
            name: ""
        )
        XCTAssertEqual(
            asset.currentBalance(),
            -100.0,
            "Initial asset balance should be +100.00"
        )

        let creditedAsset = asset.credited(by: 20.0)
        XCTAssertEqual(
            creditedAsset.currentBalance(),
            -120.0,
            "Credited asset balance should be +120.00"
        )
    }

    func testDebit() throws {
        let asset = Asset.make(
            from: [
                Asset.Transaction.debited(by: 100.0)
            ],
            name: ""
        )
        XCTAssertEqual(
            asset.currentBalance(),
            100.0,
            "Initial asset balance should be -100.00"
        )

        let creditedAsset = asset.credited(by: 20.0)
        XCTAssertEqual(
            creditedAsset.currentBalance(),
            80.0,
            "Debited asset balance should be +80.00"
        )

        let debitedAsset = asset.debited(by: 20.0)
        XCTAssertEqual(
            debitedAsset.currentBalance(),
            120.0,
            "Debited asset balance should be +120.00"
        )
    }

    func testIncrease() throws {
        let asset = Asset.make(
            from: 100.0,
            name: ""
        )
        let increasedAsset = asset.increased(by: 20.0)
        XCTAssertEqual(
            increasedAsset.currentBalance(),
            120.0,
            "When increased asset balance should be +120.0"
        )
    }

    func testDecrease() throws {
        let asset = Asset.make(
            from: 100.0,
            name: ""
        )
        let decreasedAsset = asset.decreased(by: 20.0)
        XCTAssertEqual(
            decreasedAsset.currentBalance(),
            80.0,
            "When decreased asset balance should be +80.0"
        )
    }

    func testTransactions() throws {
        let increase = Asset.Transaction.increasing(by: 50.0)

        guard case Asset.Transaction.debit(
            id: _,
            amount: let debitedAmount
        ) = increase else {
            fatalError()
        }
        XCTAssertEqual(
            debitedAmount,
            50.0,
            "Increased asset transaction should be a debit of +50.0"
        )

        let decrease = Asset.Transaction.decreasing(by: 50.0)

        guard case Asset.Transaction.credit(
            id: _,
            amount: let creditedAmount
        ) = decrease else {
            fatalError()
        }
        XCTAssertEqual(
            creditedAmount,
            50.0,
            "Decreased asset transaction should be a credit of +50.0"
        )
    }

    func testDebugDescription() throws {
        var asset = Asset.make(
            from: 1.0,
            id: "1",
            name: "Asset"
        )

        asset = asset.increased(by: 17)
        asset = asset.decreased(by: 11.5)
        asset = asset.increased(by: 101.75)
        asset = asset.increased(by: 1_101.0)
        asset = asset.increased(by: 11_101.0)
        asset = asset.increased(by: 111_101.0)
        asset = asset.decreased(by: 1_111_101.0)

        XCTAssertEqual(
            asset.debugDescription,
            """
|---------Asset---------|
|          $1.00        |
|         $17.00        |
|        ($11.50)       |
|        $101.75        |
|      $1,101.00        |
|     $11,101.00        |
|    $111,101.00        |
| ($1,111,101.00)       |
|-----------------------|
"""
        )
    }
}
