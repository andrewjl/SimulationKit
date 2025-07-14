//
//  BankTests.swift
//  
//

import Foundation

import XCTest
@testable import SimulationKit

final class BankTests: XCTestCase {
    func testBank() throws {
        let bank = Bank(eventCaptures: [], riskFreeRate: 5)

        let newRiskFreeRate = 7
        let bank2 = bank.changeRiskFreeRate(to: newRiskFreeRate)
        XCTAssertEqual(
            bank2.riskFreeRate,
            newRiskFreeRate
        )

        let results = bank2.depositCash(from: 2, amount: 100.0, at: 0)
        let duality = results.0
        let bank3 = results.1

        XCTAssertEqual(
            duality.asset.currentBalance(),
            100.0
        )

        XCTAssertEqual(
            duality.liability.currentBalance(),
            100.0
        )

        XCTAssertEqual(
            bank3.eventCaptures.count,
            1
        )

        XCTAssertEqual(
            bank3.ledger.currentBalance(),
            0
        )
    }
}
