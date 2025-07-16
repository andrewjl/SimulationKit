//
//  BankTests.swift
//  
//

import Foundation

import XCTest
@testable import SimulationKit

final class BankTests: XCTestCase {
    func testBank() throws {
        let bank = Bank()

        let newRiskFreeRate = 7

        let bank2 = bank.changeRiskFreeRate(
            to: newRiskFreeRate,
            period: 1
        )

        XCTAssertEqual(
            bank2.riskFreeRate,
            newRiskFreeRate
        )

        let bank3  = bank2.depositCash(
            from: 2,
            amount: 100.0,
            at: 0
        )

        XCTAssertEqual(
            bank3.eventCaptures.count,
            2
        )

        XCTAssertEqual(
            bank3.ledger.currentBalance(),
            0
        )
    }

    func testBankCreation() throws {
        let bank = Bank(
            riskFreeRate: 5
        )

        XCTAssertEqual(
            bank.ledger.currentBalance(),
            0
        )

        XCTAssertEqual(
            bank.riskFreeRate,
            5
        )

        XCTAssertNotNil(
            bank.reserves
        )

        XCTAssertNotNil(
            bank.deposits
        )

        XCTAssertNotNil(
            bank.loanReceivables
        )

        XCTAssertNotNil(
            bank.interestExpenses
        )

        XCTAssertNotNil(
            bank.equityCapital
        )
    }

    func testBankAccountCreation() throws {
        var bank = Bank(
            riskFreeRate: 5
        )

        bank = bank.depositCash(
            from: 2,
            amount: 5.0,
            at: 0
        )

        let account = try XCTUnwrap(
            bank.accounts[2]
        )

        XCTAssertNotNil(
            account.deposits
        )

        XCTAssertNotNil(
            account.reserves
        )

        XCTAssertNotNil(
            account.loanReceivables
        )

        XCTAssertNotNil(
            account.interestExpenses
        )
    }

    func testRiskFreeRateChange() throws {
        var bank = Bank(
            riskFreeRate: 5
        )
        
        bank = bank.changeRiskFreeRate(
            to: 10,
            period: 1
        )

        XCTAssertEqual(
            bank.riskFreeRate,
            10
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            1
        )
    }

    func testDepositCash() throws {
        var bank = Bank(
            riskFreeRate: 5
        )

        bank = bank.depositCash(
            from: 2,
            amount: 100.0,
            at: 0
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            1
        )

        XCTAssertEqual(
            bank.ledger.currentBalance(),
            .zero
        )

        let account = try XCTUnwrap(
            bank.accounts[2]
        )

        XCTAssertEqual(
            account.reserves.currentBalance(),
            100
        )

        XCTAssertEqual(
            account.deposits.currentBalance(),
            100
        )

        XCTAssertEqual(
            account.ledger.currentBalance(),
            .zero
        )
    }

    func testProvideLoan() throws {
        var bank = Bank(
            riskFreeRate: 5
        )

        let bank1 = bank.provideLoan(
            to: 2,
            amount: 100.0,
            at: 0
        )

        XCTAssertEqual(
            bank1.eventCaptures.count,
            1
        )

        let account = try XCTUnwrap(
            bank1.accounts[2]
        )

        XCTAssertEqual(
            account.deposits.currentBalance(),
            100
        )

        XCTAssertEqual(
            account.loanReceivables.currentBalance(),
            100
        )
    }

    func testDepositAccountInterestAccrual() throws {
        var bank = Bank(
            riskFreeRate: 5
        )

        bank = bank.depositCash(
            from: 2,
            amount: 100.0,
            at: 0
        ).accrueDepositInterestOnAllAccounts(
            rate: bank.riskFreeRate,
            period: 1
        )

        XCTAssertEqual(
            bank.deposits.currentBalance(),
            105.00
        )

        var depositAccount = try XCTUnwrap(
            bank.accounts[2]
        )

        XCTAssertEqual(
            depositAccount.deposits.currentBalance(),
            105.00
        )

        bank = bank.changeRiskFreeRate(
            to: 10,
            period: 1
        )
        .accrueDepositInterestOnAllAccounts(
            rate: 10,
            period: 2
        )

        XCTAssertEqual(
            bank.deposits.currentBalance(),
            115.5
        )

        depositAccount = try XCTUnwrap(
            bank.accounts[2]
        )

        XCTAssertEqual(
            depositAccount.deposits.currentBalance(),
            115.5
        )
    }

    func testEmptyDepositAccountInterestAccrual() throws {
        var bank = Bank(
            riskFreeRate: 5
        )

        bank = bank.depositCash(
            from: 2,
            amount: .zero,
            at: 0
        )

        XCTAssertEqual(
            (try XCTUnwrap(bank.accounts[2])).reserves.currentBalance(),
            .zero
        )

        XCTAssertEqual(
            (try XCTUnwrap(bank.accounts[2])).deposits.currentBalance(),
            .zero
        )

        bank = bank.accrueDepositInterestOnAllAccounts(
            rate: bank.riskFreeRate,
            period: 1
        )

        XCTAssertEqual(
            (try XCTUnwrap(bank.accounts[2])).reserves.currentBalance(),
            .zero
        )

        XCTAssertEqual(
            (try XCTUnwrap(bank.accounts[2])).deposits.currentBalance(),
            .zero
        )
    }

    func testDepositAccountInterestAccrualMultipleAccounts() throws {
        var bank = Bank(
            riskFreeRate: 5
        )

        bank = bank.depositCash(
            from: 1,
            amount: 100,
            at: 0
        )

        bank = bank.depositCash(
            from: 2,
            amount: 100,
            at: 0
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            2
        )

        XCTAssertEqual(
            bank.ledger.currentBalance(),
            0
        )

        let firstAccount = try XCTUnwrap(
            bank.accounts[1]
        )

        XCTAssertEqual(
            firstAccount.ledger.currentBalance(),
            .zero
        )

        XCTAssertEqual(
            firstAccount.deposits.currentBalance(),
            100.0
        )

        let secondAccount = try XCTUnwrap(
            bank.accounts[2]
        )

        XCTAssertEqual(
            secondAccount.ledger.currentBalance(),
            .zero
        )

        XCTAssertEqual(
            secondAccount.deposits.currentBalance(),
            100.0
        )
    }

}
