//
//  Model+Fixtures.swift
//  
//

import Foundation
@testable import SimulationKit

extension Model {
    static func makeModel() -> Model {
        let model = Model(
            rate: 5,
            initialAssetBalance: 300,
            initialLiabilityBalance: 100
        )
        return model
    }
}
