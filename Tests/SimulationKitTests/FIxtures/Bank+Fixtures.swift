//
//  Bank+Fixtures.swift
//  SimulationKit
//

@testable import SimulationKit
import Foundation

extension Bank {
    static var fixture: Bank {
        return Bank(loanRateSpread: 5)
    }
}
