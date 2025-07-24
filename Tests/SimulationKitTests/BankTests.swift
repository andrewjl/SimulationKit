//
//  BankTests.swift
//  
//

import Foundation

import XCTest
@testable import SimulationKit

final class BankTests: XCTestCase {
    func testBankCreation() throws {
        let bank = Bank(
            riskFreeRate: 5,
            loanRate: 7,
            startingCapital: 10_000
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

        XCTAssertNotNil(
            bank.interestIncome
        )

        XCTAssertEqual(
            bank.reserves.currentBalance(),
            10_000
        )

        XCTAssertEqual(
            bank.equityCapital.currentBalance(),
            10_000
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

        XCTAssertNotNil(
            account.interestIncome
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
            bank.loanRate,
            5
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
        let bank = Bank(
            riskFreeRate: 5
        )
        .provideLoan(
            to: 2,
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
            account.ledger.currentBalance(),
            .zero
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

    func testLoanInterestAccrual() throws {
        var bank = Bank(
            riskFreeRate: 5
        )
        .provideLoan(
            to: 2,
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

        XCTAssertEqual(
            bank.loanReceivables.currentBalance(),
            100.0
        )

        XCTAssertEqual(
            bank.deposits.currentBalance(),
            100.0
        )

        var depositAccount = try XCTUnwrap(
            bank.accounts[2]
        )

        XCTAssertEqual(
            depositAccount.loanReceivables.currentBalance(),
            100.00
        )

        XCTAssertEqual(
            depositAccount.deposits.currentBalance(),
            100.0
        )

        bank = bank.accrueLoanInterestOnAllAccounts(
            period: 1
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            2
        )

        depositAccount = try XCTUnwrap(
            bank.accounts[2]
        )

        XCTAssertEqual(
            depositAccount.loanReceivables.currentBalance(),
            105.00
        )

        XCTAssertEqual(
            depositAccount.deposits.currentBalance(),
            100.0
        )
    }

    func testLoanInterestAccrualMultipleAccounts() throws {
        var bank = Bank(
            riskFreeRate: 5
        )
        .provideLoan(
            to: 1,
            amount: 100.0,
            at: 0
        )
        .provideLoan(
            to: 2,
            amount: 100.0,
            at: 0
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            2
        )

        XCTAssertEqual(
            bank.ledger.currentBalance(),
            .zero
        )

        XCTAssertEqual(
            bank.loanReceivables.currentBalance(),
            200.0
        )

        XCTAssertEqual(
            bank.deposits.currentBalance(),
            200.0
        )

        var depositAccount = try XCTUnwrap(
            bank.accounts[1]
        )

        XCTAssertEqual(
            depositAccount.loanReceivables.currentBalance(),
            100.00
        )

        XCTAssertEqual(
            depositAccount.deposits.currentBalance(),
            100.0
        )

        depositAccount = try XCTUnwrap(
            bank.accounts[2]
        )

        XCTAssertEqual(
            depositAccount.loanReceivables.currentBalance(),
            100.00
        )

        XCTAssertEqual(
            depositAccount.deposits.currentBalance(),
            100.0
        )

        bank = bank.accrueLoanInterestOnAllAccounts(
            period: 1
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            4
        )

        depositAccount = try XCTUnwrap(
            bank.accounts[1]
        )

        XCTAssertEqual(
            depositAccount.loanReceivables.currentBalance(),
            105.00
        )

        XCTAssertEqual(
            depositAccount.deposits.currentBalance(),
            100.0
        )

        depositAccount = try XCTUnwrap(
            bank.accounts[2]
        )

        XCTAssertEqual(
            depositAccount.loanReceivables.currentBalance(),
            105.00
        )

        XCTAssertEqual(
            depositAccount.deposits.currentBalance(),
            100.0
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

    func testDepositAccountInterestAccrualWhenEmpty() throws {
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

        XCTAssertEqual(
            bank.eventCaptures.count,
            1
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

        XCTAssertEqual(
            bank.eventCaptures.count,
            2
        )
    }

    func testDepositAccountInterestAccrualMultipleAccounts() throws {
        var bank = Bank(
            riskFreeRate: 5
        )
        .depositCash(
            from: 1,
            amount: 100,
            at: 0
        )
        .depositCash(
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

        XCTAssertEqual(
            bank.deposits.currentBalance(),
            200.0
        )

        var firstAccount = try XCTUnwrap(
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

        var secondAccount = try XCTUnwrap(
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

        bank = bank.accrueDepositInterestOnAllAccounts(
            rate: bank.riskFreeRate,
            period: 1
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            4
        )

        XCTAssertEqual(
            bank.ledger.currentBalance(),
            0
        )

        XCTAssertEqual(
            bank.deposits.currentBalance(),
            210.0
        )

        firstAccount = try XCTUnwrap(
            bank.accounts[1]
        )

        XCTAssertEqual(
            firstAccount.ledger.currentBalance(),
            .zero
        )

        XCTAssertEqual(
            firstAccount.deposits.currentBalance(),
            105.0
        )

        secondAccount = try XCTUnwrap(
            bank.accounts[2]
        )

        XCTAssertEqual(
            secondAccount.ledger.currentBalance(),
            .zero
        )

        XCTAssertEqual(
            secondAccount.deposits.currentBalance(),
            105.0
        )
    }

    func testDepositAccountAndLoanCombinedInterestAccrual() throws {
        var bank = Bank(
            riskFreeRate: 5,
            loanRate: 7
        )
        .depositCash(
            from: 2,
            amount: 100.0,
            at: 0
        )
        .provideLoan(
            to: 2,
            amount: 100.0,
            at: 1
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            2
        )

        XCTAssertEqual(
            bank.accounts.count,
            1
        )

        XCTAssertEqual(
            bank.ledger.currentBalance(),
            .zero
        )

        XCTAssertEqual(
            bank.deposits.currentBalance(),
            200.0
        )

        bank = bank.accrueLoanInterestOnAllAccounts(
            period: 2,
        )
        .accrueDepositInterestOnAllAccounts(
            rate: bank.riskFreeRate,
            period: 2
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            4
        )

        XCTAssertEqual(
            bank.ledger.currentBalance(),
            .zero
        )

        XCTAssertEqual(
            bank.deposits.currentBalance(),
            210.0
        )

        XCTAssertEqual(
            bank.loanReceivables.currentBalance(),
            107.0
        )

        XCTAssertEqual(
            bank.interestExpenses.currentBalance(),
            10.0
        )

        XCTAssertEqual(
            bank.interestIncome.currentBalance(),
            7.0
        )
    }
}
