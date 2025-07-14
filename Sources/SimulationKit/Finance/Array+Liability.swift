//
//  Array+Liability.swift
//  
//

import Foundation

extension Array where Array.Element == Liability {
    func adjustmentTransactions(
        by percentageRate: Int
    ) -> [Array.Element.Transaction] {
        self.map { $0.adjustmentTransaction(by: percentageRate) }
    }
}
