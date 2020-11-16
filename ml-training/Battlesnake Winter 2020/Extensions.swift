//
//  Extensions.swift
//  Battlesnake Winter 2020
//
//  Created by Brandon Lantz on 11/16/20.
//

import Foundation

fileprivate var randomNormalCache: Double?
extension Double {
    static func randomNormal() -> Double {
        if let cached = randomNormalCache {
            randomNormalCache = nil
            return cached
        } else {
            let u1: Double = .random(in: 0..<1)
            let u2: Double = .random(in: 0..<2 * .pi)
            
            let r = sqrt(-2 * log(u1))
            
            randomNormalCache = r * sin(u2)
            return r * cos(u2)
        }
    }
}
