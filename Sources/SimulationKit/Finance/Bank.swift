//
//  Bank.swift
//  
//

import Foundation

struct Account: Equatable {
    var accountHolderID: UInt
    var ledger: Ledger

    var reserves: Asset {
        ledger.assets.first(where: {
            $0.name == "Reserves"
        })!
    }

    var loanReceivables : Asset {
        ledger.assets.first(where: {
            $0.name == "Loan Receivables"
        })!
    }

    var deposits: Liability {
        ledger.liabilities.first(where: {
            $0.name == "Deposits"
        })!
    }

    var interestExpenses: Asset {
        ledger.assets.first(where: {
            $0.name == "Interest Expenses"
        })!
    }

    init(
        accountHolderID: UInt
    ) {
        self.accountHolderID = accountHolderID
        self.ledger = Ledger
            .make()
            .adding(
                Asset(
                    id: UUID().uuidString,
                    name: "Reserves",
                    balance: .zero
                )
            )
            .adding(
                Asset(
                    id: UUID().uuidString,
                    name: "Loan Receivables",
                    balance: .zero
                )
            )
            .adding(
                Liability(
                    id: UUID().uuidString,
                    name: "Deposits",
                    balance: .zero
                )
            )
            .adding(
                Asset(
                    id: UUID().uuidString,
                    name: "Interest Expenses",
                    balance: .zero
                )
            )
    }
}

struct Bank: Equatable {
    var ledger: Ledger = Ledger.make()
    var eventCaptures: [Capture<Event>] = []

    var riskFreeRate: Int

    var accounts: [UInt: Account] = [:]

    var reserves: Asset {
        ledger.assets.first(where: {
            $0.name == "Reserves"
        })!
    }

    var loanReceivables : Asset {
        ledger.assets.first(where: {
            $0.name == "Loan Receivables"
        })!
    }

    var deposits: Liability {
        ledger.liabilities.first(where: {
            $0.name == "Deposits"
        })!
    }

    var equityCapital: Liability {
        ledger.liabilities.first(where: {
            $0.name == "Equity Capital"
        })!
    }

    var interestExpenses: Asset {
        ledger.assets.first(where: {
            $0.name == "Interest Expenses"
        })!
    }

    enum Event: Equatable {
        case cashDeposit(amount: Decimal, accountHolderID: UInt)
        case loanProvision(amount: Decimal, accountHolderID: UInt)
        case accrueDepositInterest(rate: Int, balance: Decimal, accountHolderID: UInt)
        case addLoanInterest(rate: Int, ledgerEvents: [Ledger.Event])
        case changeRiskFreeRate(rate: Int)
    }

    func createAccount(accountHolderID: UInt) -> Account {
        return Account(
            accountHolderID: accountHolderID
        )
    }

    func depositCash(
        from ledgerID: UInt,
        amount: Decimal,
        at period: UInt32
    ) -> Bank {
        let event = Event.cashDeposit(
            amount: amount,
            accountHolderID: ledgerID
        )

        let reservesTransaction = Asset.Transaction
            .debit(
                id: UUID().uuidString,
                amount: amount
            )
        
        let depositsTransaction = Liability.Transaction
            .credit(
                id: UUID().uuidString,
                amount: amount
            )

        let ledger = ledger
            .evented([
                .asset(
                    transaction: reservesTransaction,
                    id: reserves.id
                ),
                .liability(
                    transaction: depositsTransaction,
                    id: deposits.id
                )
            ])

        var accounts = self.accounts

        if accounts[ledgerID] == nil {
            accounts[ledgerID] = createAccount(accountHolderID: ledgerID)
        }

        var account = accounts[ledgerID]!
        let updatedLedger = account
            .ledger
            .evented([
                .asset(
                    transaction: reservesTransaction,
                    id: account.reserves.id
                ),
                .liability(
                    transaction: depositsTransaction,
                    id: account.deposits.id
                )
            ])

        account.ledger = updatedLedger
        accounts[ledgerID] = account

        let bank = Bank(
            ledger: ledger,
            eventCaptures: eventCaptures + [Capture(entity: event, timestamp: period)],
            riskFreeRate: riskFreeRate,
            accounts: accounts
        )

        return bank
    }

    func provideLoan(
        to ledgerID: UInt,
        amount: Decimal,
        at period: UInt32
    ) -> Bank {
        let event = Event.loanProvision(
            amount: amount,
            accountHolderID: ledgerID
        )

        let loanReceivablesTransaction = Asset.Transaction
            .debit(
                id: UUID().uuidString,
                amount: amount
            )
        let depositsTransaction = Liability.Transaction
            .credit(
                id: UUID().uuidString,
                amount: amount
            )

        let ledger = ledger
            .evented([
                .asset(
                    transaction: loanReceivablesTransaction,
                    id: loanReceivables.id
                ),
                .liability(
                    transaction: depositsTransaction,
                    id: deposits.id
                )
            ])

        var accounts = self.accounts

        if accounts[ledgerID] == nil {
            accounts[ledgerID] = createAccount(accountHolderID: ledgerID)
        }

        var account = accounts[ledgerID]!
        let updatedLedger = account
            .ledger
            .evented([
                .asset(
                    transaction: loanReceivablesTransaction,
                    id: account.loanReceivables.id
                ),
                .liability(
                    transaction: depositsTransaction,
                    id: account.deposits.id
                )
            ])

        account.ledger = updatedLedger
        accounts[ledgerID] = account

        let bank = Bank(
            ledger: ledger,
            eventCaptures: eventCaptures + [Capture(entity: event, timestamp: period)],
            riskFreeRate: riskFreeRate,
            accounts: accounts
        )

        return bank
    }

    func changeRiskFreeRate(
        to rate: Int,
        period: UInt32
    ) -> Self {
        Self(
            ledger: ledger,
            eventCaptures: eventCaptures + [
                Capture<Event>(
                    entity: .changeRiskFreeRate(
                        rate: rate
                    ),
                    timestamp: period
                )
            ],
            riskFreeRate: rate,
            accounts: accounts
        )
    }

    func accrueDepositInterestOnAllAccounts(
        rate: Int,
        period: UInt32
    ) -> Self {
        var result = self

        for (id, account) in accounts {
            result = result.accrueDepositInterest(
                rate: rate,
                balance: account.deposits.currentBalance(),
                accountHolderID: id,
                period: period
            )
        }

        return result
    }

    func accrueDepositInterest(
        rate: Int,
        balance: Decimal,
        accountHolderID: UInt,
        period: UInt32
    ) -> Self {
        guard var account = accounts[accountHolderID] else {
            return self
        }

        var updatedAccounts = accounts

        let accruedInterestAmount = balance.decimalizedAdjustment(
            percentage: rate
        )

        let updatedLedger = ledger.evented([
            Ledger.Event.liability(
                transaction: .credit(
                    id: UUID().uuidString,
                    amount: accruedInterestAmount
                ),
                id: deposits.id
            ),
            Ledger.Event.asset(
                transaction: .debit(
                    id: UUID().uuidString,
                    amount: accruedInterestAmount
                ),
                id: interestExpenses.id
            )
        ])

        account.ledger = account.ledger.evented([
            Ledger.Event.liability(
                transaction: .credit(
                    id: UUID().uuidString,
                    amount: accruedInterestAmount
                ),
                id: account.deposits.id
            ),
            Ledger.Event.asset(
                transaction: .debit(
                    id: UUID().uuidString,
                    amount: accruedInterestAmount
                ),
                id: account.interestExpenses.id
            )
        ])

        updatedAccounts[accountHolderID] = account

        return Bank(
            ledger: updatedLedger,
            eventCaptures: eventCaptures + [
                Capture(
                    entity: .accrueDepositInterest(
                        rate: rate,
                        balance: balance,
                        accountHolderID: accountHolderID
                    ),
                    timestamp: period
                )
            ],
            riskFreeRate: rate,
            accounts: updatedAccounts
        )
    }
}

extension Bank {
    init() {
        self.init(riskFreeRate: 0)
    }

    init(
        riskFreeRate: Int
    ) {
        self.ledger = Ledger
            .make()
            .adding(
                Asset(
                    id: UUID().uuidString,
                    name: "Reserves",
                    balance: .zero
                )
            )
            .adding(
                Asset(
                    id: UUID().uuidString,
                    name: "Loan Receivables",
                    balance: .zero
                )
            )
            .adding(
                Liability(
                    id: UUID().uuidString,
                    name: "Deposits",
                    balance: .zero
                )
            )
            .adding(
                Liability(
                    id: UUID().uuidString,
                    name: "Equity Capital",
                    balance: .zero
                )
            )
            .adding(
                Asset(
                    id: UUID().uuidString,
                    name: "Interest Expenses",
                    balance: .zero
                )
            )

        self.eventCaptures = []
        self.riskFreeRate = riskFreeRate
        self.accounts = [:]
    }
}
