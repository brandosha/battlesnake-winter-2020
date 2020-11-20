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
        
        let randomId: String = snakes[0].id
        var brains: [String: Brain] = [:]
        for snake in snakes {
            brains[snake.id] = Brain(with: brainVariables, for: snake, in: game)
        }
        
        var totalSteps = 0
        
        while game.remainingSnakes > 1 {
            game.doMoves { snake, _ in
                if snake.id == randomId { // Random snake to compare with trained
                    let scoredMoves = Game.Board.Direction.allCases.map { move -> Brain.ScoredMove in
                        return (move, .random(in: 0...1))
                    }
                    
                    // return scoredMoves.max(by: { $1.score > $0.score })!.move
                    
                    let sorted = Brain.filterAndSortMoves(scoredMoves, for: snake, in: game)
                    
                    if sorted.isEmpty { return .random() }
                    return sorted[0].move
                }
                
                let brain = brains[snake.id]!
                
                let scoredMoves = brain.getScoredMoves()
                // return scoredMoves.max { $1.score > $0.score }!.move
                
                let sorted = Brain.filterAndSortMoves(scoredMoves, for: snake, in: game)
                return sorted.first?.move ?? .random()
            }
            
            usleep(100_000)
            print("\u{001B}[2J")
            game.printBoard()
            
            totalSteps += 1
        }
        
        for snake in game.snakes {
            guard snake.isAlive else { continue }
            if snake.id == randomId { print("The random snake won") }
            break
        }
        
        print("Game length: \(totalSteps)")
    }
}
