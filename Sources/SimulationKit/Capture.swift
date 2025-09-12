//
//  Capture.swift
//  
//

import Foundation

public struct Capture<Entity> {
    public var entity: Entity
    public var timestamp: UInt32

    public init(entity: Entity, timestamp: UInt32) {
        self.entity = entity
        self.timestamp = timestamp
    }
}

extension Capture: Equatable where Entity: Equatable {}

extension Clock {
    func capture<Entity>(entity: Entity) -> Capture<Entity> {
        return Capture(entity: entity, timestamp: time)
    }
}
