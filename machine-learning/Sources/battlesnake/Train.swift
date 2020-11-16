//
//  Train.swift
//  Battlesnake Winter 2020
//
//  Created by Brandon Lantz on 11/11/20.
//

import Foundation
import ArgumentParser

struct Train: ParsableCommand {
    
    func run() throws {
        print("Training...")
        try doTraining()
    }
    
    func doTraining() throws {
        var prevGeneration: [GameResult] = []
        
        do {
            let brainVariables = try Brain.Variables.readFromFile()
            prevGeneration = [(brainVariables, 0)]
        } catch {
            print("No saved model")
        }
        
        let queues = (1...4).map { index in
            DispatchQueue(label: "Thread \(index)", qos: .background)
        }
        let group = DispatchGroup()
        
        for gen in 1...100 {
            var allResults: [GameResult] = []
            
            for queue in queues {
                group.enter()
                queue.async {
                    for _ in 1...5 {
                        let results = playThroughGame(prevGeneration)
                        allResults += results
                        // print(queue.label, "best from game \(gameNum)", results.last!.stepsSurvived)
                    }
                    
                    group.leave()
                }
            }
            
            group.wait()
            
            try allResults[0].brain.saveToFile()
            
            prevGeneration = allResults.sorted(by: { $1.stepsSurvived < $0.stepsSurvived })
            let avg = prevGeneration.reduce(0, { $0 + $1.stepsSurvived / prevGeneration.count })
            let median = prevGeneration[prevGeneration.count / 2].stepsSurvived
            
            print("Generation \(gen) - best: \(prevGeneration[0...2].map(\.stepsSurvived)), avg: \(avg), median: \(median)")
        }
    }
    
    typealias GameResult = (brain: Brain.Variables, stepsSurvived: Int)
    func playThroughGame(_ prevGeneration: [GameResult] = []) -> [GameResult] {
        var deadBrains: [GameResult] = []
        var stepsPlayed = 0
        
        let board = Game.Board(width: 11, height: 11)
        let snakes = (1...4).map { _ in Game.Snake(in: board) }
        let game = Game(board: board, snakes: snakes)
        
        var brains: [String: Brain] = [:]
        for snake in snakes {
            guard brains[snake.id] == nil else { return [] }
            
            let brain: Brain
            if prevGeneration.isEmpty {
                brain = Brain(for: snake, in: game)
            } else {
                let parents = (1...2).map { _ -> Brain.Variables in
                    let index = Int(Double(prevGeneration.count) * pow(Double.random(in: 0..<1), 2))
                    return prevGeneration[index].brain
                }
                
                brain = Brain(with: parents[0].offspring(with: parents[1]), for: snake, in: game)
            }
            
            brains[snake.id] = brain
            snake.onDeath = { deadBrains.append((brain.variables, stepsPlayed)) }
        }
        
        while game.remainingSnakes > 0 {
            game.doMoves { snake, game in
                guard let brain = brains[snake.id] else { fatalError("Missing brain") }
                
                let scoredMoves = brain.getScoredMoves()
                let sorted = Brain.filterAndSortMoves(scoredMoves, for: snake, in: game)
                
                guard !sorted.isEmpty else { return .random() }
                
                let index = Int(pow(Double.random(in: 0..<1), 2) * Double(sorted.count))
                return sorted[index].move
            }
            
            stepsPlayed += 1
        }
        
        return deadBrains
    }
}
