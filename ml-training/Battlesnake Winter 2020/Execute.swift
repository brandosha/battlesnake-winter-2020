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
    var data: String?
    
    func run() throws {
        if let data = data {
            print("Executing model...")
        } else {
            doTesting()
        }
    }
    
    func doTesting() {
        guard let brainVariables = try? Brain.Variables.readFromFile() else {
            print("No saved model")
            return
        }
        
        let board = Game.Board(width: 11, height: 11)
        let snakes = (1...4).map { _ in Game.Snake(in: board) }
        let game = Game(board: board, snakes: snakes)
        
        var brains: [String: Brain] = [:]
        for snake in snakes {
            brains[snake.id] = Brain(with: brainVariables, for: snake, in: game)
        }
        
        var totalSteps = 0
        
        while game.remainingSnakes > 0 {
            game.doMoves { snake, _ in
                let brain = brains[snake.id]!
                
                let scoredMoves = brain.getScoredMoves()
                let sorted = Brain.filterAndSortMoves(scoredMoves, for: snake, in: game)
                
                if sorted.isEmpty { return .random() }
                
                let index = Int(pow(Double.random(in: 0..<1), 2) * Double(sorted.count))
                return sorted[index].move
            }
            
            usleep(100_000)
            print("\u{001B}[2J")
            game.printBoard()
            
            totalSteps += 1
        }
        
        print("Total game length: \(totalSteps)")
    }
}
