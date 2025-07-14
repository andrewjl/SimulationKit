//
//  Reader.swift
//  
//

//import Foundation
//
//struct Reader<Deps, Data> {
//    let run: (Deps) -> Data
//}
//
//extension Reader {
//    func map<NewData>(
//        _ f: @escaping (Data) -> NewData
//    ) -> Reader<Deps, NewData> {
//        // Deps -> Data
//
//        let r: (Deps) -> NewData = { (deps: Deps) in f(self.run(deps)) }
//
//        return Reader<Deps, NewData>(
//            run: r
//        )
//
//        // Deps -> NewData
//    }
//}
