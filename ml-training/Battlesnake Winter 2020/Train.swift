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
        
        let queues = (1...4).map { index in
            DispatchQueue(label: "Thread \(index)", qos: .background)
        }
        let group = DispatchGroup()
        
        var prevGeneration: [GameResult] = []
        
        for gen in 1...10 {
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
            
            prevGeneration = allResults.sorted(by: { $1.stepsSurvived < $0.stepsSurvived })
            let avg = prevGeneration.reduce(0, { $0 + $1.stepsSurvived / prevGeneration.count })
            
            print("Generation \(gen) - best: \(prevGeneration[0].stepsSurvived), avg: \(avg)")
        }
    }
    
    typealias GameResult = (brain: Brain, stepsSurvived: Int)
    func playThroughGame(_ prevGeneration: [GameResult] = []) -> [GameResult] {
        var deadBrains: [GameResult] = []
        var stepsPlayed = 0
        
        let board = Game.Board(width: 7, height: 7)
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
                    return prevGeneration[index].brain.variables
                }
                
                brain = Brain(with: parents[0].offspring(with: parents[1]), for: snake, in: game)
            }
            
            brains[snake.id] = brain
            snake.onDeath = { deadBrains.append((brain, stepsPlayed)) }
        }
        
        while game.remainingSnakes > 0 {
            game.doMoves { snake, game in
                guard let brain = brains[snake.id] else { fatalError("Missing brain") }
                
                let scoredMoves = brain.getScoredMoves()
                let sorted = filterAndSortMoves(scoredMoves, for: snake, in: game)
                
                guard !sorted.isEmpty else { return .random() }
                
                let index = Int(pow(Double.random(in: 0..<1), 2) * Double(sorted.count))
                return sorted[index].move
            }
            
            stepsPlayed += 1
        }
        
        return deadBrains
    }
    
    func filterAndSortMoves(_ scoredMoves: [Brain.ScoredMove], for snake: Game.Snake, in game: Game) -> [Brain.ScoredMove] {
        let filtered = scoredMoves.filter { (move, score) in
            let newPos = move.appliedTo(snake.head)
            
            if (
                !(0...game.board.width - 1 ~= newPos.x) ||
                !(0...game.board.height - 1 ~= newPos.y)
            ) { return false }
            
            switch game.boardEntities[newPos]?.first {
            case .body(let otherSnake) where otherSnake.isAlive:
                return false
            case .head(let otherSnake) where otherSnake.isAlive && otherSnake !== snake:
                return false
            default: return true
            }
        }
        
        return filtered.sorted(by: { $1.score > $0.score })
    }
}
