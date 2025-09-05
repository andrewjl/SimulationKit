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
            startingCapital: 10_000,
            startingPeriod: 1
        )

        XCTAssertEqual(
            bank.ledger.currentBalance(),
            0
        )

        XCTAssertEqual(
            bank.riskFreeRate,
            5
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            1
        )

        let capture = try XCTUnwrap(
            bank.eventCaptures.first
        )

        XCTAssertEqual(
            capture.timestamp,
            1
        )

        guard case Bank.Event.receiveEquityCapital(
            amount: let amount
        ) = capture.entity else {
            XCTFail()
            return
        }

        XCTAssertEqual(
            amount,
            10_000
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

        XCTAssertNotNil(
            bank.interestReceivables
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

    func testBankCreationDefaults() throws {
        XCTAssertEqual(
            Bank().riskFreeRate,
            .zero
        )

        XCTAssertEqual(
            Bank().loanRate,
            .zero
        )
    }

    func testReceiveEquityCapital() throws {
        let bank = Bank(
            riskFreeRate: 5
        )
        .receiveEquityCapital(
            amount: 10_000.0,
            period: 0
        )

        XCTAssertEqual(
            bank.equityCapital.currentBalance(),
            10_000.0
        )

        XCTAssertEqual(
            bank.reserves.currentBalance(),
            10_000.0
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            1
        )

        XCTAssertEqual(
            bank.ledger.generalJournal.count,
            9
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

        XCTAssertNotNil(
            bank.interestReceivables
        )
    }

    func testOpenAccount() throws {
        let bank = Bank(
            riskFreeRate: 5
        )
        .openAccount(
            accountHolderID: 1,
            period: 1
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            1
        )

        let account = try XCTUnwrap(
            bank.accounts[1]
        )

        XCTAssertEqual(
            account.ledger.currentBalance(),
            .zero
        )
    }

    func testOpenAccountTwice() throws {
        let bank = Bank(
            riskFreeRate: 5
        )
        .openAccount(
            accountHolderID: 1,
            period: 1
        )
        .openAccount(
            accountHolderID: 1,
            period: 1
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            1
        )

        let account = try XCTUnwrap(
            bank.accounts[1]
        )

        XCTAssertEqual(
            account.ledger.currentBalance(),
            .zero
        )
    }

    func testCloseAccount() throws {
        let bank = Bank(
            riskFreeRate: 5
        )
        .openAccount(
            accountHolderID: 1,
            period: 1
        )
        .closeAccount(
            accountHolderID: 1,
            period: 2
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            2
        )

        let account = try XCTUnwrap(
            bank.accounts[1]
        )

        XCTAssertTrue(
            account.isClosed
        )

        XCTAssertEqual(
            account.ledger.currentBalance(),
            .zero
        )
    }

    func testCloseAccountWithNonZeroBalance() throws {
        var bank = Bank(
            riskFreeRate: 5
        )
        .openAccount(
            accountHolderID: 1,
            period: 1
        )
        .depositCash(
            from: 1,
            amount: 100.0,
            at: 1
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            2
        )

        var account = try XCTUnwrap(
            bank.accounts[1]
        )

        XCTAssertEqual(
            account.ledger.currentBalance(),
            .zero
        )

        XCTAssertEqual(
            account.deposits.currentBalance(),
            100.0
        )

        bank = bank.accrueDepositInterestOnAllAccounts(
            rate: bank.riskFreeRate,
            period: 2
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            3
        )

        bank = bank.closeAccount(
            accountHolderID: 1,
            period: 3
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            3
        )

        account = try XCTUnwrap(
            bank.accounts[1]
        )

        XCTAssertFalse(
            account.isClosed
        )
    }

    func testCloseAccountNoAccount() throws {
        let bank = Bank(
            riskFreeRate: 5,
            loanRate: 6,
            startingCapital: 10_000
        )
        .closeAccount(
            accountHolderID: 1,
            period: 1
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            1
        )
    }

    func testReopenAccount() throws {
        let bank = Bank(
            riskFreeRate: 5
        )
        .openAccount(
            accountHolderID: 1,
            period: 1
        )
        .closeAccount(
            accountHolderID: 1,
            period: 2
        )
        .openAccount(
            accountHolderID: 1,
            period: 3
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            3
        )

        let account = try XCTUnwrap(
            bank.accounts[1]
        )

        XCTAssertFalse(
            account.isClosed
        )

        XCTAssertEqual(
            account.ledger.currentBalance(),
            .zero
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
            2
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
            2
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
            2
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
            3
        )

        depositAccount = try XCTUnwrap(
            bank.accounts[2]
        )

        XCTAssertEqual(
            depositAccount.loanReceivables.currentBalance(),
            100.00
        )

        XCTAssertEqual(
            depositAccount.interestReceivables.currentBalance(),
            5.00
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
            4
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
            6
        )

        depositAccount = try XCTUnwrap(
            bank.accounts[1]
        )

        XCTAssertEqual(
            depositAccount.loanReceivables.currentBalance(),
            100.00
        )

        XCTAssertEqual(
            depositAccount.interestReceivables.currentBalance(),
            5.00
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
            depositAccount.interestReceivables.currentBalance(),
            5.00
        )

        XCTAssertEqual(
            depositAccount.deposits.currentBalance(),
            100.0
        )
    }

    func testLoanInterestAccrualNoAccount() throws {
        let bank = Bank(
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
        .accrueLoanInterest(
            rate: 5,
            balance: 100.0,
            accountHolderID: 3,
            period: 1
        )

        let loanInterestAccrualEvents = bank.eventCaptures.filter { bankEventCapture in
            if case Bank.Event.accrueLoanInterest(rate: _, balance: _, accountHolderID: _) = bankEventCapture.entity {
                return true
            }

            return false
        }

        XCTAssertTrue(
            loanInterestAccrualEvents.isEmpty
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
            2
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
            3
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
            4
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
            6
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

    func testDepositAccountInterestAccrualNoAccount() throws {
        let bank = Bank(
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
        .accrueDepositInterest(
            rate: 5,
            balance: 100,
            accountHolderID: 3,
            period: 1
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            4
        )

        let depositInterestAccrualEvents = bank.eventCaptures.filter { bankEventCapture in
            if case Bank.Event.accrueDepositInterest(rate: _, balance: _, accountHolderID: _) = bankEventCapture.entity {
                return true
            }

            return false
        }

        XCTAssertTrue(
            depositInterestAccrualEvents.isEmpty
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
            3
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
            5
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
            100.0
        )

        XCTAssertEqual(
            bank.interestExpenses.currentBalance(),
            10.0
        )

        XCTAssertEqual(
            bank.interestReceivables.currentBalance(),
            7.0
        )

        XCTAssertEqual(
            bank.interestIncome.currentBalance(),
            7.0
        )
    }

    func testReceivePaymentPrincipalAndInterest() throws {
        let bank = Bank(
            riskFreeRate: 5,
            loanRate: 7
        )
        .provideLoan(
            to: 2,
            amount: 100.0,
            at: 1
        )
        .accrueLoanInterestOnAllAccounts(
            period: 2
        )
        .accrueDepositInterestOnAllAccounts(
            rate: 5,
            period: 2
        )
        .receivePayment(
            amount: 15.0,
            from: 2,
            period: 2
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            5
        )

        let receivePaymentEvents = bank.eventCaptures.filter { bankEventCapture in
            if case Bank.Event.receiveLoanPayment(amount: _, accountHolderID: _) = bankEventCapture.entity {
                return true
            }

            return false
        }

        XCTAssertEqual(
            receivePaymentEvents.count,
            1
        )

        XCTAssertEqual(
            bank.accounts.count,
            1
        )

        XCTAssertEqual(
            bank.loanReceivables.currentBalance(),
            92.0
        )

        XCTAssertEqual(
            bank.interestReceivables.currentBalance(),
            0.0
        )

        XCTAssertEqual(
            bank.interestIncome.currentBalance(),
            7.0
        )

        XCTAssertEqual(
            bank.deposits.currentBalance(),
            105.0
        )

        let account = try XCTUnwrap(
            bank.accounts[2]
        )

        XCTAssertEqual(
            account.loanReceivables.currentBalance(),
            92.0
        )

        XCTAssertEqual(
            account.interestReceivables.currentBalance(),
            .zero
        )

        XCTAssertEqual(
            account.interestIncome.currentBalance(),
            7.0
        )

        XCTAssertEqual(
            account.deposits.currentBalance(),
            105.0
        )
    }

    func testReceivePaymentPartialInterestOnly() throws {
        let bank = Bank(
            riskFreeRate: 5,
            loanRate: 20
        )
        .provideLoan(
            to: 2,
            amount: 100.0,
            at: 1
        )
        .accrueLoanInterestOnAllAccounts(
            period: 2
        )
        .accrueDepositInterestOnAllAccounts(
            rate: 5,
            period: 2
        )
        .receivePayment(
            amount: 15.0,
            from: 2,
            period: 2
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            5
        )

        XCTAssertEqual(
            bank.accounts.count,
            1
        )

        XCTAssertEqual(
            bank.loanReceivables.currentBalance(),
            100.0
        )

        XCTAssertEqual(
            bank.interestReceivables.currentBalance(),
            5.0
        )

        XCTAssertEqual(
            bank.interestIncome.currentBalance(),
            20.0
        )

        XCTAssertEqual(
            bank.deposits.currentBalance(),
            105.0
        )

        let account = try XCTUnwrap(
            bank.accounts[2]
        )

        XCTAssertEqual(
            account.loanReceivables.currentBalance(),
            100.0
        )

        XCTAssertEqual(
            account.interestReceivables.currentBalance(),
            5.0
        )

        XCTAssertEqual(
            account.interestIncome.currentBalance(),
            20.0
        )

        XCTAssertEqual(
            account.deposits.currentBalance(),
            105.0
        )
    }

    func testReceivePaymentMultipleAccounts() throws {
        let bank = Bank(
            riskFreeRate: 5,
            loanRate: 7
        )
        .provideLoan(
            to: 2,
            amount: 100.0,
            at: 1
        )
        .provideLoan(
            to: 3,
            amount: 100.0,
            at: 1
        )
        .accrueLoanInterestOnAllAccounts(
            period: 2
        )
        .accrueDepositInterestOnAllAccounts(
            rate: 5,
            period: 2
        )
        .receivePayment(
            amount: 15.0,
            from: 2,
            period: 2
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            9
        )

        XCTAssertEqual(
            bank.accounts.count,
            2
        )

        XCTAssertEqual(
            bank.loanReceivables.currentBalance(),
            192.0
        )

        XCTAssertEqual(
            bank.interestReceivables.currentBalance(),
            7.0
        )

        XCTAssertEqual(
            bank.interestIncome.currentBalance(),
            14.0
        )

        XCTAssertEqual(
            bank.deposits.currentBalance(),
            210.0
        )

        var account = try XCTUnwrap(
            bank.accounts[2]
        )

        XCTAssertEqual(
            account.loanReceivables.currentBalance(),
            92.0
        )

        XCTAssertEqual(
            account.interestReceivables.currentBalance(),
            .zero
        )

        XCTAssertEqual(
            account.interestIncome.currentBalance(),
            7.0
        )

        XCTAssertEqual(
            account.deposits.currentBalance(),
            105.0
        )

        account = try XCTUnwrap(
            bank.accounts[3]
        )

        XCTAssertEqual(
            account.loanReceivables.currentBalance(),
            100.0
        )

        XCTAssertEqual(
            account.interestReceivables.currentBalance(),
            7.0
        )

        XCTAssertEqual(
            account.interestIncome.currentBalance(),
            7.0
        )

        XCTAssertEqual(
            account.deposits.currentBalance(),
            105.0
        )
    }

    func testReceivePaymentNoAccount() throws {
        let bank = Bank(
            riskFreeRate: 5,
            loanRate: 7,
            startingCapital: 100_000.0
        )
        .provideLoan(
            to: 2,
            amount: 100.0,
            at: 1
        )
        .provideLoan(
            to: 3,
            amount: 100.0,
            at: 1
        )
        .accrueLoanInterestOnAllAccounts(
            period: 2
        )
        .receivePayment(
            amount: 15.0,
            from: 1,
            period: 2
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            7
        )

        XCTAssertTrue(
            bank.eventCaptures.filter { bankEventCapture in
                if case Bank.Event.receiveLoanPayment(amount: _, accountHolderID: _) = bankEventCapture.entity {
                    return true
                }

                return false
            }.isEmpty
        )

        XCTAssertEqual(
            bank.accounts.count,
            2
        )
    }

    func testWithdrawCash() throws {
        var bank = Bank(
            riskFreeRate: 5,
            loanRate: 7,
            startingCapital: 1_000.0
        )
        .depositCash(
            from: 2,
            amount: 100.0,
            at: 1
        )
        .accrueDepositInterestOnAllAccounts(
            rate: 5,
            period: 2
        )
        .withdrawCash(
            amount: 20.0,
            from: 2,
            period: 2
        )

        XCTAssertEqual(
            bank.deposits.currentBalance(),
            85.0
        )

        XCTAssertEqual(
            bank.interestExpenses.currentBalance(),
            5.0
        )

        XCTAssertEqual(
            bank.reserves.currentBalance(),
            1_080.0
        )

        var account = try XCTUnwrap(
            bank.accounts[2]
        )

        XCTAssertEqual(
            account.deposits.currentBalance(),
            85.0
        )

        XCTAssertEqual(
            account.interestExpenses.currentBalance(),
            5.0
        )

        XCTAssertEqual(
            account.reserves.currentBalance(),
            80.0
        )

        bank = bank.accrueDepositInterestOnAllAccounts(
            rate: bank.riskFreeRate,
            period: 3
        )

        XCTAssertEqual(
            bank.deposits.currentBalance(),
            89.25
        )

        XCTAssertEqual(
            bank.reserves.currentBalance(),
            1_080.0
        )

        XCTAssertEqual(
            bank.interestExpenses.currentBalance(),
            9.25
        )

        account = try XCTUnwrap(
            bank.accounts[2]
        )

        XCTAssertEqual(
            account.deposits.currentBalance(),
            89.25
        )

        XCTAssertEqual(
            account.interestExpenses.currentBalance(),
            9.25
        )

        XCTAssertEqual(
            account.reserves.currentBalance(),
            80.0
        )

        bank = bank.withdrawCash(
            amount: 89.25,
            from: 2,
            period: 3
        )

        account = try XCTUnwrap(
            bank.accounts[2]
        )

        XCTAssertEqual(
            account.deposits.currentBalance(),
            .zero
        )

        XCTAssertEqual(
            account.interestExpenses.currentBalance(),
            9.25
        )
    }

    func testWithdrawCashInsufficientBalance() throws {
        let bank = Bank(
            riskFreeRate: 5,
            loanRate: 7,
            startingCapital: 1_000.0
        )
        .depositCash(
            from: 2,
            amount: 100.0,
            at: 1
        )
        .accrueDepositInterestOnAllAccounts(
            rate: 5,
            period: 2
        )
        .withdrawCash(
            amount: 120.0,
            from: 2,
            period: 2
        )

        let withdrawalEvents = bank.eventCaptures.filter { bankEventCapture in
            if case Bank.Event.withdrawCash(amount: _, accountHolderID: _) = bankEventCapture.entity {
                return true
            }

            return false
        }

        XCTAssertTrue(
            withdrawalEvents.isEmpty,
        )
    }

    func testWithdrawCashMultipleAccounts() throws {
        var bank = Bank(
            riskFreeRate: 5,
            loanRate: 7,
            startingCapital: 1_000.0
        )
        .depositCash(
            from: 2,
            amount: 100.0,
            at: 1
        )
        .depositCash(
            from: 3,
            amount: 250.0,
            at: 1
        )
        .accrueDepositInterestOnAllAccounts(
            rate: 5,
            period: 2
        )
        .withdrawCash(
            amount: 20.0,
            from: 2,
            period: 2
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            8
        )

        XCTAssertEqual(
            bank.accounts.count,
            2
        )

        XCTAssertEqual(
            bank.deposits.currentBalance(),
            347.5
        )

        XCTAssertEqual(
            bank.interestExpenses.currentBalance(),
            17.5
        )

        XCTAssertEqual(
            bank.reserves.currentBalance(),
            1_330.0
        )

        var account = try XCTUnwrap(
            bank.accounts[2]
        )

        XCTAssertEqual(
            account.deposits.currentBalance(),
            85.0
        )

        XCTAssertEqual(
            account.interestExpenses.currentBalance(),
            5.0
        )

        XCTAssertEqual(
            account.reserves.currentBalance(),
            80.0
        )

        account = try XCTUnwrap(
            bank.accounts[3]
        )

        XCTAssertEqual(
            account.deposits.currentBalance(),
            262.5
        )

        XCTAssertEqual(
            account.interestExpenses.currentBalance(),
            12.5
        )

        XCTAssertEqual(
            account.reserves.currentBalance(),
            250.0
        )

        bank = bank.accrueDepositInterestOnAllAccounts(
            rate: 5,
            period: 3
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            10
        )

        XCTAssertEqual(
            bank.deposits.currentBalance(),
            364.875
        )

        account = try XCTUnwrap(
            bank.accounts[2]
        )

        XCTAssertEqual(
            account.deposits.currentBalance(),
            89.25
        )

        XCTAssertEqual(
            account.interestExpenses.currentBalance(),
            9.25
        )

        XCTAssertEqual(
            account.reserves.currentBalance(),
            80.0
        )

        account = try XCTUnwrap(
            bank.accounts[3]
        )

        XCTAssertEqual(
            account.deposits.currentBalance(),
            275.625
        )

        XCTAssertEqual(
            account.interestExpenses.currentBalance(),
            25.625
        )

        XCTAssertEqual(
            account.reserves.currentBalance(),
            250.0
        )
    }

    func testWithdrawCashNoAccount() throws {
        let bank = Bank(
            riskFreeRate: 5,
            loanRate: 7,
            startingCapital: 1_000_000
        )
        .depositCash(
            from: 2,
            amount: 10_000.0,
            at: 1
        )
        .depositCash(
            from: 3,
            amount: 250_000.0,
            at: 1
        )
        .withdrawCash(
            amount: 200_000.0,
            from: 1,
            period: 2
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            5
        )

        XCTAssertEqual(
            bank.accounts.count,
            2
        )

        XCTAssertEqual(
            bank.reserves.currentBalance(),
            1_260_000
        )

        let accountOpeningEvents = bank.eventCaptures.filter { bankEventCapture in
            if case Bank.Event.openAccount(accountHolderID: _) = bankEventCapture.entity {
                return true
            }

            return false
        }

        XCTAssertEqual(
            accountOpeningEvents.count,
            2
        )

        let withdrawalEvents = bank.eventCaptures.filter { bankEventCapture in
            if case Bank.Event.withdrawCash(amount: _, accountHolderID: _) = bankEventCapture.entity {
                return true
            }

            return false
        }

        XCTAssertTrue(
            withdrawalEvents.isEmpty
        )
    }

    func testTransfer() throws {
        var bank = Bank(
            riskFreeRate: 5
        )
        .depositCash(
            from: 1,
            amount: 500.0,
            at: 1
        )
        .depositCash(
            from: 2,
            amount: 100.0,
            at: 1
        )
        .accrueDepositInterestOnAllAccounts(
            rate: 5,
            period: 2
        )
        .transfer(
            amount: 200.0,
            from: 1,
            to: 2,
            period: 2
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            7
        )

        XCTAssertEqual(
            bank.accounts.count,
            2
        )

        XCTAssertEqual(
            bank.reserves.currentBalance(),
            600.0
        )

        XCTAssertEqual(
            bank.deposits.currentBalance(),
            630.0
        )

        XCTAssertEqual(
            bank.interestExpenses.currentBalance(),
            30.0
        )

        var account = try XCTUnwrap(
            bank.accounts[1]
        )

        XCTAssertEqual(
            account.deposits.currentBalance(),
            325.0
        )

        XCTAssertEqual(
            account.reserves.currentBalance(),
            300.0
        )

        XCTAssertEqual(
            account.interestExpenses.currentBalance(),
            25.0
        )

        account = try XCTUnwrap(
            bank.accounts[2]
        )

        XCTAssertEqual(
            account.deposits.currentBalance(),
            305.0
        )

        XCTAssertEqual(
            account.reserves.currentBalance(),
            300.0
        )

        XCTAssertEqual(
            account.interestExpenses.currentBalance(),
            5.0
        )

        bank = bank.accrueDepositInterestOnAllAccounts(
            rate: 5,
            period: 3
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            9
        )

        XCTAssertEqual(
            bank.deposits.currentBalance(),
            661.5
        )

        XCTAssertEqual(
            bank.reserves.currentBalance(),
            600.0
        )

        XCTAssertEqual(
            bank.interestExpenses.currentBalance(),
            61.5
        )

        account = try XCTUnwrap(
            bank.accounts[1]
        )

        XCTAssertEqual(
            account.deposits.currentBalance(),
            341.25
        )

        XCTAssertEqual(
            account.reserves.currentBalance(),
            300.0
        )

        XCTAssertEqual(
            account.interestExpenses.currentBalance(),
            41.25
        )

        account = try XCTUnwrap(
            bank.accounts[2]
        )

        XCTAssertEqual(
            account.deposits.currentBalance(),
            320.25
        )

        XCTAssertEqual(
            account.reserves.currentBalance(),
            300.0
        )

        XCTAssertEqual(
            account.interestExpenses.currentBalance(),
            20.25
        )
    }

    func testTransferInsufficientBalance() throws {
        let bank = Bank(
            riskFreeRate: 5
        )
        .depositCash(
            from: 1,
            amount: 500.0,
            at: 1
        )
        .depositCash(
            from: 2,
            amount: 100.0,
            at: 1
        )
        .accrueDepositInterestOnAllAccounts(
            rate: 5,
            period: 2
        )
        .transfer(
            amount: 800.0,
            from: 1,
            to: 2,
            period: 2
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            6
        )

        XCTAssertEqual(
            bank.accounts.count,
            2
        )

        XCTAssertEqual(
            bank.reserves.currentBalance(),
            600.0
        )

        XCTAssertEqual(
            bank.deposits.currentBalance(),
            630.0
        )

        XCTAssertEqual(
            bank.interestExpenses.currentBalance(),
            30.0
        )

        var account = try XCTUnwrap(
            bank.accounts[1]
        )

        XCTAssertEqual(
            account.deposits.currentBalance(),
            525.0
        )

        XCTAssertEqual(
            account.reserves.currentBalance(),
            500.0
        )

        XCTAssertEqual(
            account.interestExpenses.currentBalance(),
            25.0
        )

        account = try XCTUnwrap(
            bank.accounts[2]
        )

        XCTAssertEqual(
            account.deposits.currentBalance(),
            105.0
        )

        XCTAssertEqual(
            account.reserves.currentBalance(),
            100.0
        )

        XCTAssertEqual(
            account.interestExpenses.currentBalance(),
            5.0
        )
    }

    func testTransferMissingDestinationAccount() throws {
        let bank = Bank(
            riskFreeRate: 5
        )
        .depositCash(
            from: 1,
            amount: 500.0,
            at: 1
        )
        .depositCash(
            from: 3,
            amount: 100.0,
            at: 1
        )
        .accrueDepositInterestOnAllAccounts(
            rate: 5,
            period: 2
        )
        .transfer(
            amount: 800.0,
            from: 1,
            to: 2,
            period: 2
        )

        XCTAssertEqual(
            bank.eventCaptures.count,
            6
        )

        XCTAssertEqual(
            bank.accounts.count,
            2
        )

        XCTAssertEqual(
            bank.reserves.currentBalance(),
            600.0
        )

        XCTAssertEqual(
            bank.deposits.currentBalance(),
            630.0
        )

        XCTAssertEqual(
            bank.interestExpenses.currentBalance(),
            30.0
        )

        var account = try XCTUnwrap(
            bank.accounts[1]
        )

        XCTAssertEqual(
            account.deposits.currentBalance(),
            525.0
        )

        XCTAssertEqual(
            account.reserves.currentBalance(),
            500.0
        )

        XCTAssertEqual(
            account.interestExpenses.currentBalance(),
            25.0
        )

        XCTAssertNil(
            bank.accounts[2]
        )

        account = try XCTUnwrap(
            bank.accounts[3]
        )

        XCTAssertEqual(
            account.deposits.currentBalance(),
            105.0
        )

        XCTAssertEqual(
            account.reserves.currentBalance(),
            100.0
        )

        XCTAssertEqual(
            account.interestExpenses.currentBalance(),
            5.0
        )
    }

    func testApplyingBankEvent() throws {
        let bank = Bank(
            riskFreeRate: 5
        ).applying(
            event: .receiveEquityCapital(
                amount: 1_000_000.0
            ),
            at: 0
        ).applying(
            event: .openAccount(
                accountHolderID: 1
            ),
            at: 1
        ).applying(
            event: .cashDeposit(
                amount: 100_000,
                accountHolderID: 1
            ),
            at: 1
        ).applying(
            event: .loanProvision(
                amount: 50_000,
                accountHolderID: 1
            ),
            at: 1
        ).applying(
            event: .changeRiskFreeRate(
                rate: 6
            ),
            at: 2
        ).applying(
            event: .accrueDepositInterest(
                rate: 6,
                balance: 150_000,
                accountHolderID: 1
            ),
            at: 2
        ).applying(
            event: .accrueLoanInterest(
                rate: 6,
                balance: 50_000,
                accountHolderID: 1
            ),
            at: 2
        ).applying(
            event: .receiveLoanPayment(
                amount: 5_000,
                accountHolderID: 1
            ),
            at: 2
        ).applying(
            event: .withdrawCash(
                amount: 10_000,
                accountHolderID: 1
            ),
            at: 2
        ).applying(
            event: .openAccount(
                accountHolderID: 2
            ),
            at: 2
        ).applying(
            event: .transfer(
                amount: 10_000,
                originAccountHolderID: 1,
                destinationAccountHolderID: 2
            ),
            at: 2
        ).applying(
            event: .withdrawCash(
                amount: 10_000,
                accountHolderID: 2
            ),
            at: 2
        ).applying(
            event: .closeAccount(
                accountHolderID: 2
            ),
            at: 3
        )

        let receiveEquityCapitalEvents = bank.eventCaptures.filter { bankEventCapture in
            if case Bank.Event.receiveEquityCapital(amount: _) = bankEventCapture.entity {
                return true
            }

            return false
        }

        XCTAssertEqual(
            receiveEquityCapitalEvents.count,
            1
        )

        let accountOpeningEvents = bank.eventCaptures.filter { bankEventCapture in
            if case Bank.Event.openAccount(accountHolderID: _) = bankEventCapture.entity {
                return true
            }

            return false
        }

        XCTAssertEqual(
            accountOpeningEvents.count,
            2
        )

        let cashDepositEvents = bank.eventCaptures.filter { bankEventCapture in
            if case Bank.Event.cashDeposit(amount: _, accountHolderID: _) = bankEventCapture.entity {
                return true
            }

            return false
        }

        XCTAssertEqual(
            cashDepositEvents.count,
            1
        )

        let depositInterestAccrualEvents = bank.eventCaptures.filter { bankEventCapture in
            if case Bank.Event.accrueDepositInterest(rate: _, balance: _, accountHolderID: _) = bankEventCapture.entity {
                return true
            }

            return false
        }

        XCTAssertEqual(
            depositInterestAccrualEvents.count,
            1
        )

        let loanProvisionEvents = bank.eventCaptures.filter { bankEventCapture in
            if case Bank.Event.loanProvision(amount: _, accountHolderID: _) = bankEventCapture.entity {
                return true
            }

            return false
        }

        XCTAssertEqual(
            loanProvisionEvents.count,
            1
        )

        let loanInterestAccrualEvents = bank.eventCaptures.filter { bankEventCapture in
            if case Bank.Event.accrueLoanInterest(rate: _, balance: _, accountHolderID: _) = bankEventCapture.entity {
                return true
            }

            return false
        }

        XCTAssertEqual(
            loanInterestAccrualEvents.count,
            1
        )

        let receiveLoanPaymentEvents = bank.eventCaptures.filter { bankEventCapture in
            if case Bank.Event.receiveLoanPayment(amount: _, accountHolderID: _) = bankEventCapture.entity {
                return true
            }

            return false
        }

        XCTAssertEqual(
            receiveLoanPaymentEvents.count,
            1
        )

        let withdrawalEvents = bank.eventCaptures.filter { bankEventCapture in
            if case Bank.Event.withdrawCash(amount: _, accountHolderID: _) = bankEventCapture.entity {
                return true
            }

            return false
        }

        XCTAssertEqual(
            withdrawalEvents.count,
            2
        )

        let transferEvents = bank.eventCaptures.filter { bankEventCapture in
            if case Bank.Event.transfer(amount: _, originAccountHolderID: _, destinationAccountHolderID: _) = bankEventCapture.entity {
                return true
            }

            return false
        }

        XCTAssertEqual(
            transferEvents.count,
            1
        )

        let accountClosingEvents = bank.eventCaptures.filter { bankEventCapture in
            if case Bank.Event.closeAccount(accountHolderID: _) = bankEventCapture.entity {
                return true
            }

            return false
        }

        XCTAssertEqual(
            accountClosingEvents.count,
            1
        )
    }

    func testBankIncomeStatement() throws {
        var bank = Bank(riskFreeRate: 5).openAccount(
            accountHolderID: 1,
            period: 0
        ).depositCash(
            from: 1,
            amount: 10_000,
            at: 0
        )

        let previousLedger = bank.ledger

        bank = bank.accrueDepositInterestOnAllAccounts(
            rate: 5,
            period: 1
        ).openAccount(
            accountHolderID: 2,
            period: 1
        ).provideLoan(
            to: 2,
            amount: 20_000,
            at: 1
        ).accrueLoanInterestOnAllAccounts(
            period: 2
        )

        let incomeStatement = try BankIncomeStatement(
            previousLedger: previousLedger,
            currentLedger: bank.ledger
        )

        XCTAssertEqual(
            incomeStatement.totalExpenses,
            500
        )

        XCTAssertEqual(
            incomeStatement.totalRevenue,
            1_000
        )
    }

    func testInvalidBankIncomeStatementMissingInterestExpenseAccounts() throws {
        var bank = Bank(
            riskFreeRate: 5
        ).openAccount(
            accountHolderID: 1,
            period: 0
        ).depositCash(
            from: 1,
            amount: 10_000,
            at: 0
        )

        let validPreviousLedger = bank.ledger

        var invalidPreviousLedger = bank.ledger
        invalidPreviousLedger.expenses.removeAll()

        bank = bank.accrueDepositInterestOnAllAccounts(
            rate: 5,
            period: 1
        )

        XCTAssertThrowsError(
            try BankIncomeStatement(
                previousLedger: invalidPreviousLedger,
                currentLedger: bank.ledger
            ),
            "Expected throw when previous ledger is missing interest expenses",
            { error in
                XCTAssertTrue(error is BankIncomeStatement.Error)
            }
        )

        var invalidCurrentLedger = bank.ledger
        invalidCurrentLedger.expenses.removeAll()

        XCTAssertThrowsError(
            try BankIncomeStatement(
                previousLedger: validPreviousLedger,
                currentLedger: invalidCurrentLedger
            ),
            "Expected throw when current ledger is missing interest expenses",
            { error in
                XCTAssertTrue(error is BankIncomeStatement.Error)
            }
        )
    }

    func testInvalidBankIncomeStatementMissingInterestRevenueAccounts() throws {
        var bank = Bank(
            riskFreeRate: 5
        ).openAccount(
            accountHolderID: 1,
            period: 0
        ).provideLoan(
            to: 1,
            amount: 20_000,
            at: 0
        )

        let validPreviousLedger = bank.ledger

        var invalidPreviousLedger = bank.ledger
        invalidPreviousLedger.revenues.removeAll()

        bank = bank.accrueLoanInterestOnAllAccounts(
            period: 1
        )

        XCTAssertThrowsError(
            try BankIncomeStatement(
                previousLedger: invalidPreviousLedger,
                currentLedger: bank.ledger
            ),
            "Expected throw when previous ledger is missing interest revenues",
            { error in
                XCTAssertTrue(error is BankIncomeStatement.Error)
            }
        )

        var invalidCurrentLedger = bank.ledger
        invalidCurrentLedger.revenues.removeAll()

        XCTAssertThrowsError(
            try BankIncomeStatement(
                previousLedger: validPreviousLedger,
                currentLedger: invalidCurrentLedger
            ),
            "Expected throw when current ledger is missing interest revenues",
            { error in
                XCTAssertTrue(error is BankIncomeStatement.Error)
            }
        )
    }
}
