//
//  LedgerTests.swift
//  
//

import XCTest
@testable import SimulationKit

final class LedgerTests: XCTestCase {
    func testConstructor() throws {
        let ledger = Ledger.make(
            assets: [
                Asset(
                    id: "1",
                    name: "",
                    balance: 250.0
                ),
                Asset(
                    id: "2",
                    name: "",
                    transactions: [
                        .increasing(by: 100.0),
                        .increasing(by: 200.0)
                    ]
                ),
            ],
            liabilities: [
                Liability(
                    id: "3",
                    name: "",
                    balance: 350.0
                )
            ],
            equities: [
                Equity(
                    id: "4",
                    name: "",
                    balance: 200.0
                ),
                Equity(
                    id: "5",
                    name: "",
                    transactions: [
                        .increasing(by: 150.0),
                        .decreasing(by: 50.0)
                    ]
                )
            ]
        )

        XCTAssertEqual(
            ledger.generalJournal.count,
            12
        )
    }

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
        XCTAssertEqual(
            ledger.currentBalance(),
            100.0
        )
        XCTAssertEqual(
            ledger.generalJournal.count,
            2
        )

        let liabilityID = UUID().uuidString
        ledger = ledger.applying(
            events: [
                .createLiability(
                    name: "",
                    accountID: liabilityID
                ),
                .postLiability(
                    transaction: .init(amount: 100.0),
                    accountID: liabilityID
                )
            ],
            at: 0
        )

        XCTAssertEqual(
            ledger.currentBalance(),
            0.0
        )
        XCTAssertEqual(
            ledger.generalJournal.count,
            4
        )
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

        assetLedger = assetLedger.applying(
            event: .postAsset(transaction: .debited(by: 50.0), accountID: "0"),
            at: 0
        )
        XCTAssertEqual(assetLedger.currentBalance(), 150.0)

        assetLedger = assetLedger.applying(
            event: .postAsset(transaction: .credited(by: 25.0), accountID: "0"),
            at: 0
        )
        XCTAssertEqual(assetLedger.currentBalance(), 125.0)

        assetLedger = assetLedger.applying(
            event: .postAsset(transaction: .increasing(by: 30.0), accountID: "0"),
            at: 0
        )
        XCTAssertEqual(assetLedger.currentBalance(), 155.0)

        assetLedger = assetLedger.applying(
            event: .postAsset(transaction: .decreasing(by: 30.0), accountID: "0"),
            at: 0
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

        liabilityLedger = liabilityLedger.applying(
            event: .postLiability(
                transaction: .credit(
                    id: "4",
                    amount: 50.0
                ),
                accountID: "0"
            ),
            at: 0
        )
        XCTAssertEqual(liabilityLedger.currentBalance(), -150.0)

        liabilityLedger = liabilityLedger.applying(
            event: .postLiability(
                transaction: .debit(
                    id: "5",
                    amount: 50.0),
                accountID: "0"
            ),
            at: 0
        )
        XCTAssertEqual(liabilityLedger.currentBalance(), -100.0)

        liabilityLedger = liabilityLedger.applying(
            event: .postLiability(transaction: .increasing(by: 20.0), accountID: "0"),
            at: 0
        )
        XCTAssertEqual(liabilityLedger.currentBalance(), -120.0)

        liabilityLedger = liabilityLedger.applying(
            event: .postLiability(transaction: .decreasing(by: 20.0), accountID: "0"),
            at: 0
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
            ],
            equities: [
                Equity(
                    id: "3",
                    name: "",
                    balance: 200.0
                )
            ]
        )
        XCTAssertEqual(ledger.currentBalance(), .zero)
        ledger = ledger
            .applying(
                events: [
                    .postAsset(transaction: .increasing(by: 15.0), accountID: "0"),
                    .postAsset(transaction: .increasing(by: 20.0), accountID: "1"),
                    .postLiability(transaction: .increasing(by: 35.0), accountID: "2")
                ],
                at: 0
            )
        XCTAssertEqual(ledger.currentBalance(), .zero)

        ledger = ledger.applying(
            event: .createExpense(
                name: "",
                accountID: "4"
            ),
            at: 0
        ).applying(
            event: .createRevenue(
                name: "",
                accountID: "5"
            ),
            at: 0
        ).applying(
            event: .createEquity(
                name: "",
                accountID: "6"
            ),
            at: 0
        ).applying(
            event: .postEquity(
                transaction: .decreasing(by: 25.0),
                accountID: "6"
            ),
            at: 0
        ).applying(
            event: .postExpense(
                transaction: .increasing(by: 50.0),
                accountID: "4"
            ),
            at: 0
        ).applying(
            event: .postRevenue(
                transaction: .increasing(by: 75.0),
                accountID: "5"
            ),
            at: 0
        )

        XCTAssertEqual(ledger.currentBalance(), .zero)
    }
}
