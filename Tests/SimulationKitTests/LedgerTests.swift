//
//  LedgerTests.swift
//  
//

import XCTest
@testable import SimulationKit

final class LedgerTests: XCTestCase {
    func testBalance() throws {
        var ledger = Ledger.make(
            assets: [
                Asset(
                    id: 0,
                    balance: 100.0
                )
            ],
            liabilities: []
        )
        XCTAssertEqual(ledger.currentBalance(), 100.0)

        ledger.liabilities.append(
            Liability(id: 0, balance: 100.0)
        )
        XCTAssertEqual(ledger.currentBalance(), 0.0)
    }

    func testSingleEventAsset() throws {
        var assetLedger = Ledger.make(
            assets: [
                Asset(
                    id: 0,
                    balance: 100.0
                )
            ],
            liabilities: []
        )
        XCTAssertEqual(assetLedger.currentBalance(), 100.0)

        assetLedger = assetLedger.tick(
            event: .asset(transaction: .debit(amount: 50.0), id: 0)
        )
        XCTAssertEqual(assetLedger.currentBalance(), 150.0)

        assetLedger = assetLedger.tick(
            event: .asset(transaction: .credit(amount: 25.0), id: 0)
        )
        XCTAssertEqual(assetLedger.currentBalance(), 125.0)

        assetLedger = assetLedger.tick(
            event: .asset(transaction: .increasing(by: 30.0), id: 0)
        )
        XCTAssertEqual(assetLedger.currentBalance(), 155.0)

        assetLedger = assetLedger.tick(
            event: .asset(transaction: .decreasing(by: 30.0), id: 0)
        )
        XCTAssertEqual(assetLedger.currentBalance(), 125.0)
    }

    func testSingleEventLiability() throws {
        var liabilityLedger = Ledger.make(
            assets: [],
            liabilities: [
                Liability(
                    id: 0,
                    balance: 100.0
                )
            ]
        )
        XCTAssertEqual(liabilityLedger.currentBalance(), -100.0)

        liabilityLedger = liabilityLedger.tick(
            event: .liability(transaction: .credit(amount: 50.0), id: 0)
        )
        XCTAssertEqual(liabilityLedger.currentBalance(), -150.0)

        liabilityLedger = liabilityLedger.tick(
            event: .liability(transaction: .debit(amount: 50.0), id: 0)
        )
        XCTAssertEqual(liabilityLedger.currentBalance(), -100.0)

        liabilityLedger = liabilityLedger.tick(
            event: .liability(transaction: .increasing(by: 20.0), id: 0)
        )
        XCTAssertEqual(liabilityLedger.currentBalance(), -120.0)

        liabilityLedger = liabilityLedger.tick(
            event: .liability(transaction: .decreasing(by: 20.0), id: 0)
        )
        XCTAssertEqual(liabilityLedger.currentBalance(), -100.0)
    }

    func testMultipleEvents() throws {
        var ledger = Ledger.make(
            assets: [
                Asset(
                    id: 0,
                    balance: 100.0
                ),
                Asset(
                    id: 1,
                    balance: 150.0
                ),
            ],
            liabilities: [
                Liability(
                    id: 0,
                    balance: 50.0
                )
            ]
        )
        XCTAssertEqual(ledger.currentBalance(), 200.0)
        ledger = ledger
            .evented([
                .asset(transaction: .debit(amount: 5.0), id: 0),
                .asset(transaction: .debit(amount: 5.0), id: 1),
                .liability(transaction: .decreasing(by: 35.0), id: 0)
            ]
        )
        XCTAssertEqual(ledger.currentBalance(), 245.0)
    }

    func tesrAdjustments() throws {
        var ledger = Ledger.make(
            assets: [
                Asset(
                    id: 0,
                    balance: 1000.0
                ),
                Asset(
                    id: 1,
                    balance: 2000.0
                ),
            ],
            liabilities: [
                Liability(
                    id: 0,
                    balance: 1500.0
                )
            ]
        )
        let expectedStartingBalance: Decimal = 1000.0 + 2000.0 - 1500.0
        XCTAssertEqual(
            ledger.currentBalance(),
            expectedStartingBalance
        )

        ledger = ledger.adjustAllAssetBalances(
            by: 2
        )

        let expectedPostAssetAdjustmentBalance: Decimal = 1020.0 + 2040.0 - 1500.0
        XCTAssertEqual(
            ledger.currentBalance(),
            expectedPostAssetAdjustmentBalance
        )

        ledger = ledger.adjustAllLiabilityBalances(
            by: 3
        )

        let expectedPostLiabilityAdjustmentBalance: Decimal = 1020.0 + 2040.0 - 1545.0
        XCTAssertEqual(
            ledger.currentBalance(),
            expectedPostLiabilityAdjustmentBalance
        )
    }
}
