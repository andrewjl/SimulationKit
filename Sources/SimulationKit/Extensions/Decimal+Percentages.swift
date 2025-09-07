//
//  Decimal+Percentages.swift
//  SimulationKit
//

import Foundation

extension Decimal {
    func computeAdjustment(percentage: UInt) -> Self {
        let decimalized = Decimal(percentage)/Decimal(100)
        return (Decimal(1) + decimalized) * self
    }

    func decimalizedAdjustment(percentage: Int) -> Self {
        return (Decimal(percentage)/Decimal(100))*self
    }
}
