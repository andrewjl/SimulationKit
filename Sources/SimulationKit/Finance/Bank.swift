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
            $0.name == Bank.reservesAccountName
        })!
    }

    var loanReceivables : Asset {
        ledger.assets.first(where: {
            $0.name == Bank.loanReceivablesAccountName
        })!
    }

    var deposits: Liability {
        ledger.liabilities.first(where: {
            $0.name == Bank.depositsAccountName
        })!
    }

    var interestExpenses: Asset {
        ledger.assets.first(where: {
            $0.name == Bank.interestExpensesAccountName
        })!
    }

    var interestIncome: Liability {
        ledger.liabilities.first(where: {
            $0.name == Bank.interestIncomeAccountName
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
                    name: Bank.reservesAccountName,
                    balance: .zero
                )
            )
            .adding(
                Asset(
                    id: UUID().uuidString,
                    name: Bank.loanReceivablesAccountName,
                    balance: .zero
                )
            )
            .adding(
                Liability(
                    id: UUID().uuidString,
                    name: Bank.depositsAccountName,
                    balance: .zero
                )
            )
            .adding(
                Asset(
                    id: UUID().uuidString,
                    name: Bank.interestExpensesAccountName,
                    balance: .zero
                )
            )
            .adding(
                Liability(
                    id: UUID().uuidString,
                    name: Bank.interestIncomeAccountName,
                    balance: .zero
                )
            )
    }
}

struct Bank: Equatable {
    static let depositsAccountName: String = "Deposits"
    static let reservesAccountName: String = "Reserves"
    static let loanReceivablesAccountName: String = "Loan Receivables"
    static let equityCapitalAccountName: String = "Equity Capital"
    static let interestExpensesAccountName: String = "Interest Expenses"
    static let interestIncomeAccountName: String = "Interest Income"

    var ledger: Ledger = Ledger.make()
    var eventCaptures: [Capture<Event>] = []

    var riskFreeRate: Int

    var accounts: [UInt: Account] = [:]

    var reserves: Asset {
        ledger.assets.first(where: {
            $0.name == Bank.reservesAccountName
        })!
    }

    var loanReceivables : Asset {
        ledger.assets.first(where: {
            $0.name == Bank.loanReceivablesAccountName
        })!
    }

    var deposits: Liability {
        ledger.liabilities.first(where: {
            $0.name == Bank.depositsAccountName
        })!
    }

    var equityCapital: Liability {
        ledger.liabilities.first(where: {
            $0.name == Bank.equityCapitalAccountName
        })!
    }

    var interestExpenses: Asset {
        ledger.assets.first(where: {
            $0.name == Bank.interestExpensesAccountName
        })!
    }

    var interestIncome: Liability {
        ledger.liabilities.first(where: {
            $0.name == Bank.interestIncomeAccountName
        })!
    }

    enum Event: Equatable {
        case cashDeposit(amount: Decimal, accountHolderID: UInt)
        case loanProvision(amount: Decimal, accountHolderID: UInt)
        case accrueDepositInterest(rate: Int, balance: Decimal, accountHolderID: UInt)
        case accrueLoanInterest(rate: Int, balance: Decimal, accountHolderID: UInt)
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
                    accountID: reserves.id
                ),
                .liability(
                    transaction: depositsTransaction,
                    accountID: deposits.id
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
                    accountID: account.reserves.id
                ),
                .liability(
                    transaction: depositsTransaction,
                    accountID: account.deposits.id
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
                    accountID: loanReceivables.id
                ),
                .liability(
                    transaction: depositsTransaction,
                    accountID: deposits.id
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
                    accountID: account.loanReceivables.id
                ),
                .liability(
                    transaction: depositsTransaction,
                    accountID: account.deposits.id
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
                accountID: deposits.id
            ),
            Ledger.Event.asset(
                transaction: .debit(
                    id: UUID().uuidString,
                    amount: accruedInterestAmount
                ),
                accountID: interestExpenses.id
            )
        ])

        account.ledger = account.ledger.evented([
            Ledger.Event.liability(
                transaction: .credit(
                    id: UUID().uuidString,
                    amount: accruedInterestAmount
                ),
                accountID: account.deposits.id
            ),
            Ledger.Event.asset(
                transaction: .debit(
                    id: UUID().uuidString,
                    amount: accruedInterestAmount
                ),
                accountID: account.interestExpenses.id
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
    
    func accrueLoanInterestOnAllAccounts(
        rate: Int,
        period: UInt32
    ) -> Self {
        var result = self

        for (id, account) in accounts {
            result = result.accrueLoanInterest(
                rate: rate,
                balance: account.loanReceivables.currentBalance(),
                accountHolderID: id,
                period: period
            )
        }

        return result
    }

    func accrueLoanInterest(
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
            Ledger.Event.asset(
                transaction: .debit(
                    id: UUID().uuidString,
                    amount: accruedInterestAmount
                ),
                accountID: loanReceivables.id
            ),
            Ledger.Event.liability(
                transaction: .credit(
                    id: UUID().uuidString,
                    amount: accruedInterestAmount
                ),
                accountID: interestIncome.id
            )
        ])

        account.ledger = account.ledger.evented([
            Ledger.Event.asset(
                transaction: .debit(
                    id: UUID().uuidString,
                    amount: accruedInterestAmount
                ),
                accountID: account.loanReceivables.id
            ),
            Ledger.Event.liability(
                transaction: .credit(
                    id: UUID().uuidString,
                    amount: accruedInterestAmount
                ),
                accountID: account.interestIncome.id
            )
        ])

        updatedAccounts[account.accountHolderID] = account

        return Bank(
            ledger: updatedLedger,
            eventCaptures: eventCaptures + [
                Capture(
                    entity: .accrueLoanInterest(
                        rate: rate,
                        balance: balance,
                        accountHolderID: accountHolderID
                    ),
                    timestamp: period
                )
            ],
            riskFreeRate: riskFreeRate,
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
                    name: Bank.reservesAccountName,
                    balance: .zero
                )
            )
            .adding(
                Asset(
                    id: UUID().uuidString,
                    name: Bank.loanReceivablesAccountName,
                    balance: .zero
                )
            )
            .adding(
                Liability(
                    id: UUID().uuidString,
                    name: Bank.depositsAccountName,
                    balance: .zero
                )
            )
            .adding(
                Liability(
                    id: UUID().uuidString,
                    name: Bank.equityCapitalAccountName,
                    balance: .zero
                )
            )
            .adding(
                Asset(
                    id: UUID().uuidString,
                    name: Bank.interestExpensesAccountName,
                    balance: .zero
                )
            )
            .adding(
                Liability(
                    id: UUID().uuidString,
                    name: Bank.interestIncomeAccountName,
                    balance: .zero
                )
            )

        self.eventCaptures = []
        self.riskFreeRate = riskFreeRate
        self.accounts = [:]
    }
}
