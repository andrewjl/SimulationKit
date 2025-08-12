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
                    id: UUID().uuidString,
                    name: "",
                    balance: 100.0
                )
            ],
            liabilities: []
        )
        XCTAssertEqual(ledger.currentBalance(), 100.0)

        ledger.liabilities.append(
            Liability(
                id: UUID().uuidString,
                name: "",
                balance: 100.0
            )
        )
        XCTAssertEqual(ledger.currentBalance(), 0.0)
    }

    func testSingleEventAsset() throws {
        var assetLedger = Ledger.make(
            assets: [
                Asset(
                    id: "0",
                    name: "",
                    balance: 100.0
                )
            ],
            liabilities: []
        )
        XCTAssertEqual(assetLedger.currentBalance(), 100.0)

        assetLedger = assetLedger.applyingEvent(
            event: .asset(transaction: .debited(by: 50.0), accountID: "0")
        )
        XCTAssertEqual(assetLedger.currentBalance(), 150.0)

        assetLedger = assetLedger.applyingEvent(
            event: .asset(transaction: .credited(by: 25.0), accountID: "0")
        )
        XCTAssertEqual(assetLedger.currentBalance(), 125.0)

        assetLedger = assetLedger.applyingEvent(
            event: .asset(transaction: .increasing(by: 30.0), accountID: "0")
        )
        XCTAssertEqual(assetLedger.currentBalance(), 155.0)

        assetLedger = assetLedger.applyingEvent(
            event: .asset(transaction: .decreasing(by: 30.0), accountID: "0")
        )
        XCTAssertEqual(assetLedger.currentBalance(), 125.0)
    }

    func testSingleEventLiability() throws {
        var liabilityLedger = Ledger.make(
            assets: [],
            liabilities: [
                Liability(
                    id: "0",
                    name: "",
                    balance: 100.0
                )
            ]
        )
        XCTAssertEqual(liabilityLedger.currentBalance(), -100.0)

        liabilityLedger = liabilityLedger.applyingEvent(
            event: .liability(
                transaction: .credit(
                    id: "4",
                    amount: 50.0
                ),
                accountID: "0"
            )
        )
        XCTAssertEqual(liabilityLedger.currentBalance(), -150.0)

        liabilityLedger = liabilityLedger.applyingEvent(
            event: .liability(
                transaction: .debit(
                    id: "5",
                    amount: 50.0),
                accountID: "0"
            )
        )
        XCTAssertEqual(liabilityLedger.currentBalance(), -100.0)

        liabilityLedger = liabilityLedger.applyingEvent(
            event: .liability(transaction: .increasing(by: 20.0), accountID: "0")
        )
        XCTAssertEqual(liabilityLedger.currentBalance(), -120.0)

        liabilityLedger = liabilityLedger.applyingEvent(
            event: .liability(transaction: .decreasing(by: 20.0), accountID: "0")
        )
        XCTAssertEqual(liabilityLedger.currentBalance(), -100.0)
    }

    func testMultipleEvents() throws {
        var ledger = Ledger.make(
            assets: [
                Asset(
                    id: "0",
                    name: "",
                    balance: 100.0
                ),
                Asset(
                    id: "1",
                    name: "",
                    balance: 150.0
                ),
            ],
            liabilities: [
                Liability(
                    id: "2",
                    name: "",
                    balance: 50.0
                )
            ]
        )
        XCTAssertEqual(ledger.currentBalance(), 200.0)
        ledger = ledger
            .applyingEvents([
                .asset(transaction: .debited(by: 5.0), accountID: "0"),
                .asset(transaction: .debited(by: 5.0), accountID: "1"),
                .liability(transaction: .decreasing(by: 35.0), accountID: "2")
            ]
        )
        XCTAssertEqual(ledger.currentBalance(), 245.0)
    }
}
