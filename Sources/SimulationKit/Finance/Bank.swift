//
//  Bank.swift
//  
//

import Foundation

struct BankIncomeStatement: Equatable {
    let totalRevenue: Decimal
    let totalExpenses: Decimal

    init(
        previousLedger: Ledger,
        currentLedger: Ledger
    ) {
        guard let previousInterestIncomeAccount = previousLedger
            .revenues
            .first(where: { $0.name == Bank.interestIncomeAccountName }) else {
            precondition(
                false,
                "No interest income account in previous ledger"
            )
        }

        guard let currentInterestIncomeAccount = currentLedger
            .revenues
            .first(where: { $0.name == Bank.interestIncomeAccountName }) else {
            precondition(
                false,
                "No interest income account in current ledger"
            )
        }

        guard let previousInterestExpensesAccount = previousLedger
            .revenues
            .first(where: { $0.name == Bank.interestExpensesAccountName }) else {
            precondition(
                false,
                "No interest expense account in previous ledger"
            )
        }

        guard let currentInterestExpensesAccount = currentLedger
            .revenues
            .first(where: { $0.name == Bank.interestExpensesAccountName }) else {
            precondition(
                false,
                "No interest expense account in current ledger"
            )
        }

        self.totalRevenue = currentInterestIncomeAccount.currentBalance() - previousInterestIncomeAccount.currentBalance()
        self.totalExpenses = currentInterestExpensesAccount.currentBalance() - previousInterestExpensesAccount.currentBalance()
    }
}

struct Account: Equatable {
    var accountHolderID: UInt
    var ledger: Ledger

    var isClosed: Bool = false

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

    var interestExpenses: Expense {
        ledger.expenses.first(where: {
            $0.name == Bank.interestExpensesAccountName
        })!
    }

    var interestIncome: Revenue {
        ledger.revenues.first(where: {
            $0.name == Bank.interestIncomeAccountName
        })!
    }

    var interestReceivables: Asset {
        ledger.assets.first(where: {
            $0.name == Bank.interestReceivablesAccount
        })!
    }

    init(
        accountHolderID: UInt,
        period: UInt32
    ) {
        self.accountHolderID = accountHolderID
        self.ledger = Ledger
            .make()
            .adding(
                Asset(
                    id: UUID().uuidString,
                    name: Bank.reservesAccountName,
                    balance: .zero
                ),
                at: period
            )
            .adding(
                Asset(
                    id: UUID().uuidString,
                    name: Bank.loanReceivablesAccountName,
                    balance: .zero
                ),
                at: period
            )
            .adding(
                Liability(
                    id: UUID().uuidString,
                    name: Bank.depositsAccountName,
                    balance: .zero
                ),
                at: period
            )
            .adding(
                Expense(
                    id: UUID().uuidString,
                    name: Bank.interestExpensesAccountName,
                    balance: .zero
                ),
                at: period
            )
            .adding(
                Revenue(
                    id: UUID().uuidString,
                    name: Bank.interestIncomeAccountName,
                    balance: .zero
                ),
                at: period
            )
            .adding(
                Asset(
                    id: UUID().uuidString,
                    name: Bank.interestReceivablesAccount,
                    balance: .zero
                ),
                at: period
            )
    }

    mutating func close() {
        isClosed = true
    }

    mutating func reopen() {
        isClosed = false
    }
}

struct Bank: Equatable {
    static let depositsAccountName: String = "Deposits"
    static let reservesAccountName: String = "Reserves"
    static let loanReceivablesAccountName: String = "Loan Receivables"
    static let equityCapitalAccountName: String = "Equity Capital"
    static let interestReceivablesAccount = "Interest Receivables"
    static let interestExpensesAccountName: String = "Interest Expenses"
    static let interestIncomeAccountName: String = "Interest Income"

    var ledger: Ledger = Ledger.make()
    var eventCaptures: [Capture<Event>] = []

    var riskFreeRate: Int
    var loanRate: Int

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

    var equityCapital: Equity {
        ledger.equities.first(where: {
            $0.name == Bank.equityCapitalAccountName
        })!
    }

    var interestExpenses: Expense {
        ledger.expenses.first(where: {
            $0.name == Bank.interestExpensesAccountName
        })!
    }

    var interestIncome: Revenue {
        ledger.revenues.first(where: {
            $0.name == Bank.interestIncomeAccountName
        })!
    }

    var interestReceivables: Asset {
        ledger.assets.first(where: {
            $0.name == Bank.interestReceivablesAccount
        })!
    }

    enum Event: Equatable {
        case receiveEquityCapital(amount: Decimal)
        case openAccount(accountHolderID: UInt)
        case closeAccount(accountHolderID: UInt)
        case cashDeposit(amount: Decimal, accountHolderID: UInt)
        case loanProvision(amount: Decimal, accountHolderID: UInt)
        case accrueDepositInterest(rate: Int, balance: Decimal, accountHolderID: UInt)
        case accrueLoanInterest(rate: Int, balance: Decimal, accountHolderID: UInt)
        case changeRiskFreeRate(rate: Int)
        case receiveLoanPayment(amount: Decimal, accountHolderID: UInt)
        case withdrawCash(amount: Decimal, accountHolderID: UInt)
        case transfer(amount: Decimal, originAccountHolderID: UInt, destinationAccountHolderID: UInt)
    }

    func createAccount(
        accountHolderID: UInt,
        at period: UInt32
    ) -> Account {
        return Account(
            accountHolderID: accountHolderID,
            period: period
        )
    }

    func receiveEquityCapital(
        amount: Decimal,
        period: UInt32
    ) -> Self {
        let reservesTransaction = Asset.Transaction.debited(
            by: amount
        )
        let equityCapitalTransaction = Equity.Transaction.credited(
            by: amount
        )

        return Bank(
            ledger: ledger
                .applying(
                    events: [
                        .postAsset(
                            transaction: reservesTransaction,
                            accountID: reserves.id
                        ),
                        .postEquity(
                            transaction: equityCapitalTransaction,
                            accountID: equityCapital.id
                        )
                    ],
                    at: period
                ),
            eventCaptures: eventCaptures + [
                Capture(
                    entity: .receiveEquityCapital(
                        amount: amount
                    ),
                    timestamp: period
                )
            ],
            riskFreeRate: riskFreeRate,
            loanRate: loanRate,
            accounts: accounts
        )
    }

    func openAccount(
        accountHolderID: UInt,
        period: UInt32
    ) -> Self {

        if let account = accounts[accountHolderID], !account.isClosed {
            return self
        } else if var account = accounts[accountHolderID], account.isClosed {
            account.reopen()

            var updatedAccounts = accounts
            updatedAccounts[accountHolderID] = account

            return Bank(
                ledger: ledger,
                eventCaptures: eventCaptures + [
                    Capture(
                        entity: .openAccount(
                            accountHolderID: accountHolderID
                        ),
                        timestamp: period
                    )
                ],
                riskFreeRate: riskFreeRate,
                loanRate: loanRate,
                accounts: updatedAccounts
            )
        } else {
            var updatedAccounts = accounts
            updatedAccounts[accountHolderID] = createAccount(
                accountHolderID: accountHolderID,
                at: period
            )

            return Bank(
                ledger: ledger,
                eventCaptures: eventCaptures + [
                    Capture(
                        entity: .openAccount(
                            accountHolderID: accountHolderID
                        ),
                        timestamp: period
                    )
                ],
                riskFreeRate: riskFreeRate,
                loanRate: loanRate,
                accounts: updatedAccounts
            )
        }
    }

    func closeAccount(
        accountHolderID: UInt,
        period: UInt32
    ) -> Self {
        guard var account = accounts[accountHolderID] else {
            return self
        }

        guard account.deposits.currentBalance() == .zero else {
            return self
        }

        account.close()

        var updatedAccounts = accounts
        updatedAccounts[accountHolderID] = account

        return Bank(
            ledger: ledger,
            eventCaptures: eventCaptures + [
                Capture(
                    entity: .closeAccount(
                        accountHolderID: accountHolderID
                    ),
                    timestamp: period
                )
            ],
            riskFreeRate: riskFreeRate,
            loanRate: loanRate,
            accounts: updatedAccounts
        )
    }

    func depositCash(
        from ledgerID: UInt,
        amount: Decimal,
        at period: UInt32
    ) -> Bank {
        var newlyRecordedEvents = [
            Event.cashDeposit(
                amount: amount,
                accountHolderID: ledgerID
            )
        ]

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

        var accounts = self.accounts

        if accounts[ledgerID] == nil {
            accounts[ledgerID] = createAccount(
                accountHolderID: ledgerID,
                at: period
            )

            newlyRecordedEvents.append(
                .openAccount(
                    accountHolderID: ledgerID
                )
            )
        }

        var account = accounts[ledgerID]!
        let updatedLedger = account
            .ledger
            .applying(
                events: [
                    .postAsset(
                        transaction: reservesTransaction,
                        accountID: account.reserves.id
                    ),
                    .postLiability(
                        transaction: depositsTransaction,
                        accountID: account.deposits.id
                    )
                ],
                at: period
            )

        account.ledger = updatedLedger
        accounts[ledgerID] = account

        let bank = Bank(
            ledger: ledger
                .applying(
                    events: [
                        .postAsset(
                            transaction: reservesTransaction,
                            accountID: reserves.id
                        ),
                        .postLiability(
                            transaction: depositsTransaction,
                            accountID: deposits.id
                        )
                    ],
                    at: period
                ),
            eventCaptures: eventCaptures + newlyRecordedEvents.map {
                Capture(entity: $0, timestamp: period)
            },
            riskFreeRate: riskFreeRate,
            loanRate: loanRate,
            accounts: accounts
        )

        return bank
    }

    func provideLoan(
        to ledgerID: UInt,
        amount: Decimal,
        at period: UInt32
    ) -> Bank {
        var newlyRecordedEvents = [
            Event.loanProvision(
                amount: amount,
                accountHolderID: ledgerID
            )
        ]

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

        var accounts = self.accounts

        if accounts[ledgerID] == nil {
            accounts[ledgerID] = createAccount(
                accountHolderID: ledgerID,
                at: period
            )

            newlyRecordedEvents.append(
                .openAccount(
                    accountHolderID: ledgerID
                )
            )
        }

        var account = accounts[ledgerID]!
        let updatedLedger = account
            .ledger
            .applying(
                events: [
                    .postAsset(
                        transaction: loanReceivablesTransaction,
                        accountID: account.loanReceivables.id
                    ),
                    .postLiability(
                        transaction: depositsTransaction,
                        accountID: account.deposits.id
                    )
                ],
                at: period
            )

        account.ledger = updatedLedger
        accounts[ledgerID] = account

        let bank = Bank(
            ledger: ledger
                .applying(
                    events: [
                        .postAsset(
                            transaction: loanReceivablesTransaction,
                            accountID: loanReceivables.id
                        ),
                        .postLiability(
                            transaction: depositsTransaction,
                            accountID: deposits.id
                        )
                    ],
                    at: period
            ),
            eventCaptures: eventCaptures + newlyRecordedEvents.map {
                Capture(entity: $0, timestamp: period)
            },
            riskFreeRate: riskFreeRate,
            loanRate: loanRate,
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
            loanRate: loanRate,
            accounts: accounts
        )
    }

    func accrueDepositInterestOnAllAccounts(
        rate: Int,
        period: UInt32
    ) -> Self {
        var result = self

        for (id, account) in accounts.filter({
            $0.value.isClosed == false
        }) {
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

        let depositsTransaction = Liability.Transaction
            .credited(by: accruedInterestAmount)
        let interestExpensesTransaction = Expense.Transaction
            .debited(by: accruedInterestAmount)

        let updatedLedger = ledger.applying(
            events: [
                Ledger.Event.postLiability(
                    transaction: depositsTransaction,
                    accountID: deposits.id
                ),
                Ledger.Event.postExpense(
                    transaction: interestExpensesTransaction,
                    accountID: interestExpenses.id
                )
            ],
            at: period
        )

        account.ledger = account.ledger.applying(
            events: [
                Ledger.Event.postLiability(
                    transaction: depositsTransaction,
                    accountID: account.deposits.id
                ),
                Ledger.Event.postExpense(
                    transaction: interestExpensesTransaction,
                    accountID: account.interestExpenses.id
                )
            ],
            at: period
        )

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
            loanRate: loanRate,
            accounts: updatedAccounts
        )
    }

    func accrueLoanInterestOnAllAccounts(
        period: UInt32
    ) -> Self {
        var result = self

        for (id, account) in accounts.filter({
            $0.value.isClosed == false &&
            $0.value.loanReceivables.currentBalance() > 0
        }) {
            result = result.accrueLoanInterest(
                rate: loanRate,
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

        account.ledger = account.ledger.applying(
            events: [
                Ledger.Event.postAsset(
                    transaction: .debit(
                        id: UUID().uuidString,
                        amount: accruedInterestAmount
                    ),
                    accountID: account.interestReceivables.id
                ),
                Ledger.Event.postRevenue(
                    transaction: .credit(
                        id: UUID().uuidString,
                        amount: accruedInterestAmount
                    ),
                    accountID: account.interestIncome.id
                )
            ],
            at: period
        )

        updatedAccounts[account.accountHolderID] = account

        return Bank(
            ledger: ledger.applying(
                events: [
                    Ledger.Event.postAsset(
                        transaction: .debit(
                            id: UUID().uuidString,
                            amount: accruedInterestAmount
                        ),
                        accountID: interestReceivables.id
                    ),
                    Ledger.Event.postRevenue(
                        transaction: .credit(
                            id: UUID().uuidString,
                            amount: accruedInterestAmount
                        ),
                        accountID: interestIncome.id
                    )
                ],
                at: period
            ),
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
            loanRate: loanRate,
            accounts: updatedAccounts
        )
    }

    func receivePayment(
        amount: Decimal,
        from accountHolderID: UInt,
        period: UInt32
    ) -> Self {
        guard var account = accounts[accountHolderID] else {
            return self
        }

        var updatedAccounts = accounts
        var updatedLedger = ledger

        let interestDue = account.interestReceivables.currentBalance()

        let principalPaymentAmount: Decimal
        let interestPaymentAmount: Decimal

        if amount > interestDue {
            principalPaymentAmount = amount - interestDue
            interestPaymentAmount = interestDue
        } else {
            principalPaymentAmount = 0
            interestPaymentAmount = amount
        }

        let reservesTransaction = Asset.Transaction
            .debited(
                by: amount
            )
        let interestReceivablesTransaction = Asset.Transaction
            .credited(
                by: interestPaymentAmount
            )

        if principalPaymentAmount > 0 {
            let loanReceivablesTransaction = Asset.Transaction
                .credited(
                    by: principalPaymentAmount
                )

            account.ledger = account.ledger.applying(
                events: [
                    .postAsset(
                        transaction: loanReceivablesTransaction,
                        accountID: account.loanReceivables.id
                    )
                ],
                at: period
            )

            updatedLedger = updatedLedger.applying(
                events: [
                    .postAsset(
                        transaction: loanReceivablesTransaction,
                        accountID: loanReceivables.id
                    )
                ],
                at: period
            )
        }

        account.ledger = account.ledger.applying(
            events: [
                .postAsset(
                    transaction: reservesTransaction,
                    accountID: account.reserves.id
                ),
                .postAsset(
                    transaction: interestReceivablesTransaction,
                    accountID: account.interestReceivables.id
                )
            ],
            at: period
        )

        updatedLedger = updatedLedger.applying(
            events: [
                .postAsset(
                    transaction: reservesTransaction,
                    accountID: reserves.id
                ),
                .postAsset(
                    transaction: interestReceivablesTransaction,
                    accountID: interestReceivables.id
                )
            ],
            at: period
        )

        updatedAccounts[accountHolderID] = account

        return Bank(
            ledger: updatedLedger,
            eventCaptures: eventCaptures + [
                Capture(
                    entity: .receiveLoanPayment(
                        amount: amount,
                        accountHolderID: accountHolderID
                    ),
                    timestamp: period
                )
            ],
            riskFreeRate: riskFreeRate,
            loanRate: loanRate,
            accounts: updatedAccounts
        )
    }

    func withdrawCash(
        amount: Decimal,
        from accountHolderID: UInt,
        period: UInt32
    ) -> Self {
        guard var account = accounts[accountHolderID] else {
            return self
        }

        guard amount < account.deposits.currentBalance() else {
            return self
        }

        var updatedAccounts = accounts
        var updatedLedger = ledger

        let reservesTransaction = Asset.Transaction
            .credited(
                by: amount
            )
        let depositsTransaction = Liability.Transaction
            .debited(
                by: amount
            )

        account.ledger = account.ledger.applying(
            events: [
                .postAsset(
                    transaction: reservesTransaction,
                    accountID: account.reserves.id
                ),
                .postLiability(
                    transaction: depositsTransaction,
                    accountID: account.deposits.id
                )
            ],
            at: period
        )

        updatedLedger = updatedLedger.applying(
            events: [
                .postAsset(
                    transaction: reservesTransaction,
                    accountID: reserves.id
                ),
                .postLiability(
                    transaction: depositsTransaction,
                    accountID: deposits.id
                )
            ],
            at: period
        )

        updatedAccounts[accountHolderID] = account

        return Bank(
            ledger: updatedLedger,
            eventCaptures: eventCaptures + [
                Capture(
                    entity: .withdrawCash(
                        amount: amount,
                        accountHolderID: accountHolderID
                    ),
                    timestamp: period
                )
            ],
            riskFreeRate: riskFreeRate,
            loanRate: loanRate,
            accounts: updatedAccounts
        )
    }

    func transfer(
        amount: Decimal,
        from originAccountHolderID: UInt,
        to destinationAccountHolderID: UInt,
        period: UInt32
    ) -> Self {
        guard var originAccount = accounts[originAccountHolderID],
              var destinationAccount = accounts[destinationAccountHolderID] else {
            return self
        }

        guard originAccount.deposits.currentBalance() >= amount else {
            return self
        }

        var updatedAccounts = accounts
        var updatedLedger = ledger

        let originReservesTransaction = Asset.Transaction
            .credited(
                by: amount
            )
        let originDepositsTransaction = Liability.Transaction
            .debited(
                by: amount
            )

        originAccount.ledger = originAccount.ledger.applying(
            events: [
                .postAsset(
                    transaction: originReservesTransaction,
                    accountID: originAccount.reserves.id
                ),
                .postLiability(
                    transaction: originDepositsTransaction,
                    accountID: originAccount.deposits.id
                )
            ],
            at: period
        )

        updatedLedger = updatedLedger.applying(
            events: [
                .postAsset(
                    transaction: originReservesTransaction,
                    accountID: reserves.id
                ),
                .postLiability(
                    transaction: originDepositsTransaction,
                    accountID: deposits.id
                )
            ],
            at: period
        )

        let destinationReservesTransaction = Asset.Transaction
            .debited(
                by: amount
            )
        let destinationDepositsTransaction = Liability.Transaction
            .credited(
                by: amount
            )

        destinationAccount.ledger = destinationAccount.ledger.applying(
            events: [
                .postAsset(
                    transaction: destinationReservesTransaction,
                    accountID: destinationAccount.reserves.id
                ),
                .postLiability(
                    transaction: destinationDepositsTransaction,
                    accountID: destinationAccount.deposits.id
                )
            ],
            at: period
        )

        updatedLedger = updatedLedger.applying(
            events: [
                .postAsset(
                    transaction: destinationReservesTransaction,
                    accountID: reserves.id
                ),
                .postLiability(
                    transaction: destinationDepositsTransaction,
                    accountID: deposits.id
                )
            ],
            at: period
        )

        updatedAccounts[originAccountHolderID] = originAccount
        updatedAccounts[destinationAccountHolderID] = destinationAccount

        return Bank(
            ledger: updatedLedger,
            eventCaptures: eventCaptures + [
                Capture(
                    entity: .transfer(
                        amount: amount,
                        originAccountHolderID: originAccountHolderID,
                        destinationAccountHolderID: destinationAccountHolderID
                    ),
                    timestamp: period
                )
            ],
            riskFreeRate: riskFreeRate,
            loanRate: loanRate,
            accounts: updatedAccounts
        )
    }

    func applyingEvent(
        event: Bank.Event,
        period: UInt32
    ) -> Self {
        switch event {
        case .receiveEquityCapital(amount: let amount):
            return receiveEquityCapital(
                amount: amount,
                period: period
            )
        case .openAccount(accountHolderID: let accountHolderID):
            return openAccount(
                accountHolderID: accountHolderID,
                period: period
            )
        case .closeAccount(accountHolderID: let accountHolderID):
            return closeAccount(
                accountHolderID: accountHolderID,
                period: period
            )
        case .cashDeposit(amount: let amount, accountHolderID: let accountHolderID):
            return depositCash(
                from: accountHolderID,
                amount: amount,
                at: period
            )
        case .loanProvision(amount: let amount, accountHolderID: let accountHolderID):
            return provideLoan(
                to: accountHolderID,
                amount: amount,
                at: period
            )
        case .accrueDepositInterest(rate: let rate, balance: let balance, accountHolderID: let accountHolderID):
            return accrueDepositInterest(
                rate: rate,
                balance: balance,
                accountHolderID: accountHolderID,
                period: period
            )
        case .accrueLoanInterest(rate: let rate, balance: let balance, accountHolderID: let accountHolderID):
            return accrueLoanInterest(
                rate: rate,
                balance: balance,
                accountHolderID: accountHolderID,
                period: period
            )
        case .changeRiskFreeRate(rate: let rate):
            return changeRiskFreeRate(
                to: rate,
                period: period
            )
        case .receiveLoanPayment(amount: let amount, accountHolderID: let accountHolderID):
            return receivePayment(
                amount: amount,
                from: accountHolderID,
                period: period
            )
        case .withdrawCash(amount: let amount, accountHolderID: let accountHolderID):
            return withdrawCash(
                amount: amount,
                from: accountHolderID,
                period: period
            )
        case .transfer(amount: let amount, originAccountHolderID: let originAccountHolderID, destinationAccountHolderID: let destinationAccountHolderID):
            return transfer(
                amount: amount,
                from: originAccountHolderID,
                to: destinationAccountHolderID,
                period: period
            )
        }
    }

    init() {
        self.init(
            riskFreeRate: 0,
            loanRate: 0
        )
    }

    init(
        riskFreeRate: Int
    ) {
        self.init(
            riskFreeRate: riskFreeRate,
            loanRate: riskFreeRate
        )
    }

    init(
        riskFreeRate: Int,
        loanRate: Int,
        startingCapital: Decimal = .zero,
        startingPeriod: UInt32 = 0
    ) {
        let ledger = Ledger
            .make()
            .adding(
                Asset(
                    id: UUID().uuidString,
                    name: Bank.reservesAccountName,
                    balance: startingCapital
                ),
                at: startingPeriod
            )
            .adding(
                Asset(
                    id: UUID().uuidString,
                    name: Bank.loanReceivablesAccountName,
                    balance: .zero
                ),
                at: startingPeriod
            )
            .adding(
                Liability(
                    id: UUID().uuidString,
                    name: Bank.depositsAccountName,
                    balance: .zero
                ),
                at: startingPeriod
            )
            .adding(
                Equity(
                    id: UUID().uuidString,
                    name: Bank.equityCapitalAccountName,
                    balance: startingCapital
                ),
                at: startingPeriod
            )
            .adding(
                Expense(
                    id: UUID().uuidString,
                    name: Bank.interestExpensesAccountName,
                    balance: .zero
                ),
                at: startingPeriod
            )
            .adding(
                Revenue(
                    id: UUID().uuidString,
                    name: Bank.interestIncomeAccountName,
                    balance: .zero
                ),
                at: startingPeriod
            )
            .adding(
                Asset(
                    id: UUID().uuidString,
                    name: Bank.interestReceivablesAccount,
                    balance: .zero
                ),
                at: startingPeriod
            )

        let eventCaptures = startingCapital == .zero ? [] : [
            Capture(
                entity: Event.receiveEquityCapital(
                    amount: startingCapital
                ),
                timestamp: startingPeriod
            )
        ]

        self.init(
            ledger: ledger,
            eventCaptures: eventCaptures,
            riskFreeRate: riskFreeRate,
            loanRate: loanRate,
            accounts: [:]
        )
    }

    init(
        ledger: Ledger,
        eventCaptures: [Capture<Event>],
        riskFreeRate: Int,
        loanRate: Int,
        accounts: [UInt: Account]
    ) {
        self.ledger = ledger
        self.eventCaptures = eventCaptures
        self.riskFreeRate = riskFreeRate
        self.loanRate = loanRate
        self.accounts = accounts
    }
}
