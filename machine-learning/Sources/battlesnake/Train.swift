//
//  Train.swift
//  Battlesnake Winter 2020
//
//  Created by Brandon Lantz on 11/11/20.
//

import Foundation
import ArgumentParser

struct TrainingData {
    static let board = Game.Board(width: 11, height: 11)
    
    static var savedBrainVariables = try? Brain.Variables.readFromFile()
    
    static var population: [Train.GameResult] = []
    
    /*static var bestBrain: Train.GameResult?
    static var newBest = false*/
}

struct Train: ParsableCommand {
    
    @Option(name: .shortAndLong)
    var iterations = 100
    
    @Option(name: .shortAndLong)
    var population = 100
    
    @Option(name: .shortAndLong)
    var outFile = "model_variables.dat"
    
    func run() throws {
        print("Training...")
        try doTraining()
    }
    
    func doTraining() throws {
        // var prevGeneration: [GameResult] = []
        
        for gen in 1...iterations {
            let population = generatePopulation()
            
            guard population.count.isMultiple(of: 4) else { fatalError("Population must be divisible by 4") }
            
            var gameBrains: [(index: Int, brain: Brain.Variables)] = []
            for individual in 0..<population.count {
                let agent = (individual, population[individual].brain)
                gameBrains.append(agent)
                
                if gameBrains.count == 4 {
                    var stepsPlayed = 0
                    
                    var brains: [String: Brain] = [:]
                    let snakes = gameBrains.map { (index, variables) -> Game.Snake in
                        let snake = Game.Snake(in: TrainingData.board)
                        snake.onDeath = {
                            TrainingData.population[index].stepsSurvived = stepsPlayed
                        }
                        
                        return snake
                    }
                    let game = Game(board: TrainingData.board, snakes: snakes)
                    
                    for (index, (_, variables)) in gameBrains.enumerated() {
                        let snake = snakes[index]
                        brains[snake.id] = Brain(with: variables, for: snake, in: game)
                    }
                    
                    while game.remainingSnakes > 0 {
                        game.doMoves { snake, _ in
                            guard let brain = brains[snake.id] else {
                                fatalError("Missing brain")
                            }
                            
                            let scoredMoves = brain.getScoredMoves()
                            // return scoredMoves.max(by: { $1.score > $0.score })!.move
                            
                            let sorted = Brain.filterAndSortMoves(scoredMoves, for: snake, in: game)
                            
                            if sorted.isEmpty { return .random() }
                            
                            return sorted[0].move
                        }
                        
                        stepsPlayed += 1
                    }
                    
                    gameBrains = []
                }
                // let results = playThroughGame(prevGeneration)
                // allResults += results
            }
            
            TrainingData.population.sort { $1.stepsSurvived < $0.stepsSurvived }
            let generation = TrainingData.population
            
            let avg = generation.reduce(0, { $0 + $1.stepsSurvived })  / generation.count
            let median = generation[generation.count / 2].stepsSurvived
            
            print("Generation \(gen) - best: \(TrainingData.population[0...2].map(\.stepsSurvived)), avg: \(avg), median: \(median)")
            
            try TrainingData.population[0].brain.saveToFile(outFile)
            
            /*var allResults: [GameResult] = []
            
            for _ in 1...25 {
                let results = playThroughGame(prevGeneration)
                allResults += results
            }
            
            prevGeneration = allResults.sorted(by: { $1.stepsSurvived < $0.stepsSurvived })
            let avg = prevGeneration.reduce(0, { $0 + $1.stepsSurvived / prevGeneration.count })
            let median = prevGeneration[prevGeneration.count / 2].stepsSurvived
            
            print("Generation \(gen) - best: \(prevGeneration[0...2].map(\.stepsSurvived)), avg: \(avg), median: \(median)")
            
            if newBest {
                print("new best: \(bestBrain!.stepsSurvived)")
                newBest = false
                try bestBrain!.brain.saveToFile()
            } else if let bestBrain = bestBrain {
                prevGeneration.insert(bestBrain, at: 0)
            }*/
        }
    }
    
    func generatePopulation() -> [GameResult] {
        let prevPopulation = TrainingData.population
        var newPopulation: [Train.GameResult] = []
        
        if prevPopulation.isEmpty {
            if let savedBrain = TrainingData.savedBrainVariables {
                let tenth = population / 10
                
                let provenCount = tenth
                let mutatedCount = 8 * tenth
                let newCount = tenth
                
                for _ in 1...provenCount {
                    newPopulation.append((savedBrain, 0))
                }
                for _ in 1...mutatedCount {
                    newPopulation.append((savedBrain.mutated(), 0))
                }
                for _ in 1...newCount {
                    newPopulation.append((.random(TrainingData.board), 0))
                }
            } else {
                for _ in 1...population {
                    newPopulation.append((.random(TrainingData.board), 0))
                }
            }
        } else {
            let tenth = population / 10
            
            let provenCount = tenth
            let offspringCount = 8 * tenth
            let newCount = tenth
            
            newPopulation += prevPopulation.prefix(provenCount) // Keep the top performers
            
            let scoreSum = prevPopulation.reduce(0, { $0 + $1.stepsSurvived })
            
            for _ in 1...offspringCount {
                let parents = (1...2).map { _ -> Brain.Variables in
                    let random = Int.random(in: 1...scoreSum)
                    
                    var probSum = 0
                    var index = -1
                    while probSum < random {
                        index += 1
                        probSum += prevPopulation[index].stepsSurvived
                    }
                    
                    return prevPopulation[index].brain
                }
                
                let offspring = parents[0].offspring(with: parents[1])
                
                newPopulation.append((offspring, 0))
            }
            for _ in 1...newCount {
                newPopulation.append((.random(TrainingData.board), 0))
            }
        }
        
        TrainingData.population = newPopulation.shuffled()
        return TrainingData.population
    }
    
    typealias GameResult = (brain: Brain.Variables, stepsSurvived: Int)
    /*func playThroughGame(_ prevGeneration: [GameResult] = []) -> [GameResult] {
        var deadBrains: [GameResult] = []
        var stepsPlayed = 0
        
        let board = Game.Board(width: 11, height: 11)
        let snakes = (1...4).map { _ in Game.Snake(in: board) }
        let game = Game(board: board, snakes: snakes)
        
        var brains: [String: Brain] = [:]
        for snake in snakes {
            guard brains[snake.id] == nil else { return [] }
            
            let variables: Brain.Variables // Keeping this separate to prevent data leak in onDeath closure
            let brain: Brain
            if prevGeneration.isEmpty {
                brain = Brain(for: snake, in: game)
                variables = brain.variables
            } else {
                let parents = (1...2).map { _ -> GameResult in
                    let maxIndex = prevGeneration.count - 1
                    var index = 0
                    while index < maxIndex && 0.2 < .random(in: 0...1) {
                        index += 1
                    }
                    // let index = Int(Double(prevGeneration.count) * pow(Double.random(in: 0..<1), 4))
                    return prevGeneration[index]
                }
                
                /*let best = Double(prevGeneration[0].stepsSurvived)
                let norm = parents.map { Double($0.stepsSurvived) / best }
                let prob = 1 - norm[0] * norm[1]*/
                variables = parents[0].brain.offspring(
                    with: parents[1].brain,
                    mutationProbablitiy: 0.01)
                brain = Brain(with: variables, for: snake, in: game)
            }
            
            brains[snake.id] = brain
            snake.onDeath = {
                let result = (variables, stepsPlayed)
                deadBrains.append(result)
                
                if let best = bestBrain?.stepsSurvived, stepsPlayed <= best {
                    return
                } else {
                    bestBrain = result
                    newBest = true
                }
            }
        }
        
        while game.remainingSnakes > 0 {
            game.doMoves { snake, _ in
                guard let brain = brains[snake.id] else { fatalError("Missing brain") }
                
                let scoredMoves = brain.getScoredMoves()
                return scoredMoves.max(by: { $1.score > $0.score })!.move
                
                /*
                let sorted = Brain.filterAndSortMoves(scoredMoves, for: snake, in: game)
                
                guard !sorted.isEmpty else { return .random() }
                
                let index = 0 // Int(pow(Double.random(in: 0..<1), 2) * Double(sorted.count))
                return sorted[index].move
                */
            }
            
            stepsPlayed += 1
        }
        
        return deadBrains
    }*/
}
