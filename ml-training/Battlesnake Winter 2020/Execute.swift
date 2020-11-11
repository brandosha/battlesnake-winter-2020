//
//  Execute.swift
//  Battlesnake Winter 2020
//
//  Created by Brandon Lantz on 11/11/20.
//

import Foundation
import ArgumentParser

struct Execute: ParsableCommand {
    @Argument(help: "The game data in JSON format")
    var data: String
    
    func run() throws {
        print("Executing model...")
    }
}
