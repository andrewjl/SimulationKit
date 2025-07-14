//
//  Bank.swift
//  
//

import Foundation

struct Deposit: Equatable {
    var id: UInt
    var ledgerID: UInt
    var bank: Duality
    var depositor: Duality
}

struct Bank: Equatable {
    var ledger: Ledger = Ledger.make()
    var eventCaptures: [Capture<Event>] = []

    var riskFreeRate: Int

    var deposits: [UInt: Deposit] = [:]

    enum Event: Equatable {
        case cashDeposit(amount: Decimal, ledgerID: UInt)
        case addDepositInterest(rate: Int, ledgerEvents: [Ledger.Event])
    }

    func depositCash(
        from ledgerID: UInt,
        amount: Decimal,
        at period: UInt32
    ) -> (Duality, Bank) {
        let deposit = depositBookEntry(amount: amount, to: ledgerID)
        let event = Event.cashDeposit(amount: amount, ledgerID: ledgerID)

        let ledger = ledger.adding(deposit.bank.asset).adding(deposit.bank.liability)
        let bank = Bank(
            ledger: ledger,
            eventCaptures: eventCaptures + [Capture(entity: event, timestamp: period)],
            riskFreeRate: riskFreeRate
        )

        return (deposit.depositor, bank)
    }

    func changeRiskFreeRate(to rate: Int) -> Self {
        Self(
            eventCaptures: eventCaptures,
            riskFreeRate: rate
        )
    }

    func depositBookEntry(
        amount: Decimal,
        to ledgerID: UInt
    ) -> Deposit {
        return Deposit(
            id: UInt(deposits.count),
            ledgerID: ledgerID,
            bank: Duality(
                asset: Asset.make(from: amount),
                liability: Liability.make(from: amount)
            ),
            depositor: Duality(
                asset: Asset.make(from: amount),
                liability: Liability.make(from: amount)
            )
        )
    }

    func computeDepositEvents() -> [Event] {
        return []
    }
}
