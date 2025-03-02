//
//  Simulator.swift
//  
//

import Foundation

class Simulator {
    var historian: Historian

    init(historian: Historian) {
        self.historian = historian
    }

    init() {
        self.historian = Historian()
    }

    @discardableResult func execute(
        model: Model,
        runsCount: UInt = 1
    ) -> [Run] {
        var runs: [Run] = []

        for _ in 1...runsCount {
            let run = self.run(model: model)
            runs.append(run)
        }

        return runs
    }

    private func run(
        model: Model
    ) -> Run {
        let execModel = Simulation.make(from: model)
        let clock = Clock()

        var steps: [Step] = []

        for _ in 0..<model.duration {
            let step = execModel.tick(clock: clock)
            steps.append(step)
            historian.process(step: step)
        }

        let handle = historian.records.last?.id ?? 0
        let finalLedger = Capture(entity: execModel.ledger, timestamp: steps.last?.currentPeriod ?? 0)

        let run = Run(
            finalLedger: finalLedger,
            totalPeriods: model.duration,
            handle: handle
        )

        return run
    }
}

struct Step {
    var ledger: Ledger
    var events: [Ledger.Event]
    var currentPeriod: UInt32
    var totalPeriods: UInt32
}

struct Run {
    var finalLedger: Capture<Ledger>
    var totalPeriods: UInt32
    var handle: UInt
}
