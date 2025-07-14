//
//  Array+Asset.swift
//  SimulationKit
//

import Foundation

extension Array where Array.Element == Asset {
    func adjustmentTransactions(by percentageRate: Int) -> [Array.Element.Transaction] {
        self.map { $0.adjustmentTransaction(by: percentageRate) }
    }
}
