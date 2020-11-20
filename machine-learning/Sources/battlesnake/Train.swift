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
    
    static var population: [Train.AgentFitness] = []
    static var gamesPerSnake: [Int] = []
}

struct Train: ParsableCommand {
    
    @Option(name: .shortAndLong)
    var iterations = 100
    
    @Option(name: .shortAndLong)
    var population = 100
    
    @Option(name: .shortAndLong)
    var outFile = "model_variables.dat"
    
    @Flag(name: .shortAndLong)
    var snapshots = false
    
    func run() throws {
        print("Training...")
        // testGeneticAlgorithm()
        try doTraining()
    }
    
    func testGeneticAlgorithm() {
        var allVariables: [Brain.Variables] = (1...100).map { _ in
            let weights: [Matrix] = [
                .random(rows: 2, cols: 3),
                .random(rows: 3, cols: 1)
            ]
            let biases = weights.map { Matrix.random(rows: 1, cols: $0.dimensions.cols) }
            
            return Brain.Variables(weights: weights, biases: biases)
        }
        
        var results: [(brain: Brain.Variables, fitness: Double)] = []
        
        for gen in 1...100 {
            for variables in allVariables {
                var totalFitness: Double = 0
                
                for _ in 1...100 {
                    let inputs: [Int] = [.random(in: 0...1), .random(in: 0...1)]
                    let modelInputs: Matrix = [
                        inputs.map { Double($0) }
                    ]
                    
                    var output = modelInputs .* variables.weights[0] + variables.biases[0]
                    output = output.map(relu)
                    output = output .* variables.weights[1] + variables.biases[1]
                    output = output.map(sigmoid)
                    
                    let outResult = output[0, 0]
                    let fitness = 1 - abs(Double(inputs[0] ^ inputs[1]) - outResult)
                    totalFitness += fitness
                    
                    /*if 0.01 > .random(in: 0...1) {
                        print("\(inputs[0]) XOR \(inputs[1]) = \(round(outResult * 100) / 100), actual: \(inputs[0] ^ inputs[1])")
                    }*/
                }
                
                results.append((variables, totalFitness))
            }
            
            results.sort(by: { $1.fitness < $0.fitness })
            
            print("Test generation \(gen) - best: \(results[0].fitness)")
            
            allVariables = (1...100).map { _ in
                let parents = (1...2).map { _ -> Brain.Variables in
                    var index = 0
                    while index < results.count - 1 && 0.1 > .random(in: 0...1) {
                        index += 1
                    }
                    
                    return results[index].brain
                }
                
                
                return parents[0].offspring(with: parents[1])
            }
            
            results = []
        }
    }
    
    func doTraining() throws {
        for gen in 1...iterations {
            let population = generatePopulation()
            
            TrainingData.gamesPerSnake = [Int](repeating: 0, count: population.count)
            
            for individual in 0..<population.count {
                setFitness(for: individual)
                
                // print(individual, TrainingData.gamesPerSnake)
            }
            
            /*guard TrainingData.gamesPerSnake.allSatisfy({ $0 == TrainingData.gamesPerSnake[0] }) else {
                print(TrainingData.gamesPerSnake)
                fatalError("A snake did not play the same amount of games as the others")
            }*/
            
            for index in TrainingData.population.indices {
                let gamesPlayed = Double(TrainingData.gamesPerSnake[index])
                TrainingData.population[index].fitness /= gamesPlayed
            }
            
            TrainingData.population.sort { $1.fitness < $0.fitness }
            let generation = TrainingData.population
            
            let avg = generation.reduce(0.0, { $0 + $1.fitness }) / Double(generation.count)
            let median = generation[generation.count / 2].fitness
            
            if (snapshots) { print("\n\n----------") }
            let bestStr = String(format: "%.2f", TrainingData.population[0].fitness)
            let avgStr = String(format: "%.2f", avg)
            let medianStr = String(format: "%.2f", median)
            print("Generation \(gen) - best: \(bestStr), avg: \(avgStr), median: \(medianStr)")
            if (snapshots) { print("----------\n\n") }
            
            try TrainingData.population[0].brain.saveToFile(outFile)
        }
    }
    
    typealias Agent = (snake: Game.Snake, index: Int)
    func setFitness(for agentIndex: Int) {
        let agentVariables = TrainingData.population[agentIndex].brain
        
        let remainingIndices = (agentIndex + 1)..<TrainingData.population.count
        
        var stepsPlayed = 0
        var stepsSurvived: [String: Int] = [:]
        var enemies: [Agent] = []
        for index in remainingIndices {
            let snake = Game.Snake(in: TrainingData.board)
            snake.onDeath = { _ in stepsSurvived[snake.id] = stepsPlayed }
            
            enemies.append((snake, index))
            
            guard enemies.count == 3 else { continue }
            let thisSnake = Game.Snake(in: TrainingData.board)
            thisSnake.onDeath = { _ in stepsSurvived[thisSnake.id] = stepsPlayed }
            
            var snakes = [thisSnake]
            var agents: [Agent] = [(thisSnake, agentIndex)]
            for enemy in enemies {
                snakes.append(enemy.snake)
                agents.append(enemy)
            }
            
            let game = Game(board: TrainingData.board, snakes: snakes)
            
            var brains: [String: Brain] = [thisSnake.id: Brain(with: agentVariables, for: thisSnake, in: game)]
            for enemy in enemies {
                let enemyVariables = TrainingData.population[enemy.index].brain
                brains[enemy.snake.id] = Brain(with: enemyVariables, for: enemy.snake, in: game)
            }
            
            while game.remainingSnakes > 1 {
                game.doMoves { snake, _ in
                    guard let brain = brains[snake.id] else { fatalError("Missing brain") }
                    
                    let scored = brain.getScoredMoves()
                    // return scored.max(by: { $1.score > $0.score })!.move
                    
                    let sorted = Brain.filterAndSortMoves(scored, for: snake, in: game)
                    return sorted.first?.move ?? .random()
                }
                
                stepsPlayed += 1
            }
            
            for agent in agents {
                let fitness = stepsSurvived[agent.snake.id] ?? stepsPlayed
                /*fitness *= snake.kills + 1
                if snake.isAlive { fitness *= 4 }
                fitness += agent.snake.length*/
                
                TrainingData.gamesPerSnake[agent.index] += 1
                TrainingData.population[agent.index].fitness += Double(fitness)
            }
            
            stepsPlayed = 0
            stepsSurvived = [:]
            enemies = []
        }
    }
    
    func generatePopulation() -> [AgentFitness] {
        let prevPopulation = TrainingData.population
        var newPopulation: [Train.AgentFitness] = []
        
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
            
            newPopulation += prevPopulation.prefix(provenCount).map {
                ($0.brain, 0)
            } // Keep the top performers resetting fitness
            
            let scoreSum = prevPopulation.reduce(0, { $0 + $1.fitness })
            
            for _ in 1...offspringCount {
                let parents = (1...2).map { _ -> Brain.Variables in
                    let random = Double.random(in: 1...scoreSum)
                    
                    var probSum = 0.0
                    var index = -1
                    while probSum < random {
                        index += 1
                        probSum += prevPopulation[index].fitness
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
    
    typealias AgentFitness = (brain: Brain.Variables, fitness: Double)
}
