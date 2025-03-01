//
//  Capture.swift
//  
//

import Foundation

struct Capture<Entity> {
    var entity: Entity
    var timestamp: UInt32
}

extension Clock {
    func capture<Entity>(entity: Entity) -> Capture<Entity> {
        return Capture(entity: entity, timestamp: time)
    }
}
