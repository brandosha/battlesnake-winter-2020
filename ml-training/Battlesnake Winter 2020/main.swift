//
//  main.swift
//  Battlesnake Winter 2020
//
//  Created by Brandon Lantz on 11/11/20.
//

import Foundation
import ArgumentParser


struct MainApp: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "battlesnake",
        abstract: "Battlesnake AI swift tool",
        subcommands: [Train.self, Execute.self],
        defaultSubcommand: Train.self)
}

MainApp.main()
