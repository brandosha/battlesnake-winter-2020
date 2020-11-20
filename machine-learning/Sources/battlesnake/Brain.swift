//
//  Brain.swift
//  Battlesnake Winter 2020
//
//  Created by Brandon Lantz on 11/13/20.
//

import Foundation

struct Matrix: ExpressibleByArrayLiteral {
    typealias ArrayLiteralElement = [Double]
    
    var values: [[Double]]
    
    typealias Dimensions = (rows: Int, cols: Int)
    let dimensions: Dimensions
    
    init(arrayLiteral elements: [Double]...) {
        self.init(elements)
    }
    
    init(_ values: [[Double]]) {
        let rows = values.count
        guard rows > 0 else {
            self.values = values
            self.dimensions = (0, 0)
            
            return
        }
        
        let cols = values[0].count
        guard values.allSatisfy({ $0.count == cols }) else { fatalError("Invalid matrix") }
        
        self.values = values
        self.dimensions = (rows, cols)
    }
    
    private init (_ values: [[Double]], rows: Int, cols: Int) {
        self.values = values
        self.dimensions = (rows, cols)
    }
    
    static func random(rows: Int, cols: Int) -> Matrix {
        let values = (1...rows).map { _ in
            (1...cols).map { _ in
                Double.randomNormal()
            }
        }
        
        return Matrix(values, rows: rows, cols: cols)
    }
    
    static func random(_ dimensions: Dimensions) -> Matrix {
        return .random(rows: dimensions.rows, cols: dimensions.cols)
    }
    
    subscript(row: Int, col: Int) -> Double {
        get {
            return values[row][col]
        } set {
            values[row][col] = newValue
        }
    }
    
    func row(_ row: Int) -> [Double] {
        return values[row]
    }
    
    func col(_ col: Int) -> [Double] {
        return values.map { $0[col] }
    }
    
    func map(_ f: (_ value: Double, _ row: Int, _ col: Int) -> Double) -> Matrix {
        var newMatrix = self
        
        for row in 0...dimensions.rows - 1 {
            for col in 0...dimensions.cols - 1 {
                newMatrix[row, col] = f(newMatrix[row, col], row, col)
            }
        }
        
        return newMatrix
    }
    
    func map(_ f: (_ value: Double) -> Double) -> Matrix {
        return self.map { val, _, _ in f(val) }
    }
    
    var data: Data {
        let allValues = [Double](values.joined())
        let dimensions = [self.dimensions.rows, self.dimensions.cols].map { UInt32($0) }
        
        var byteArray: [UInt8] = []
        dimensions.withUnsafeBytes { byteArray.append(contentsOf: $0) }
        allValues.withUnsafeBytes { byteArray.append(contentsOf: $0) }
        
        return Data(byteArray)
    }
    
    init(data: Data) {
        var dimensionsData: [UInt32] = [0, 0]
        _ = dimensionsData.withUnsafeMutableBytes { data[0..<8].copyBytes(to: $0) }
        
        let rows = Int(dimensionsData[0])
        let cols = Int(dimensionsData[1])
        
        let byteCount = 8 + rows * cols * 8
        var allValues = [Double](repeating: 0, count: rows * cols)
        _ = allValues.withUnsafeMutableBytes { data[8..<byteCount].copyBytes(to: $0) }
        
        var values: [[Double]] = []
        for row in 0..<rows {
            let start = row * cols
            let end = start + cols - 1
            
            values.append([Double](allValues[start...end]))
        }
        
        self.dimensions = (rows, cols)
        self.values = values
    }
}

infix operator .* : MultiplicationPrecedence
func .* (lhs: Matrix, rhs: Matrix) -> Matrix {
    guard (lhs.dimensions.cols == rhs.dimensions.rows) else { fatalError("Incompatible matrix dimensions") }
    
    let outDim: Matrix.Dimensions = (lhs.dimensions.rows, rhs.dimensions.cols)
    
    let values: [[Double]] = (0...outDim.rows - 1).map { row in
        (0...outDim.cols - 1).map { col in
            let colVals = rhs.col(col)
            let rowVals = lhs.row(row)
            
            var sum = 0.0
            for (index, rowVal) in rowVals.enumerated() {
                sum += rowVal * colVals[index]
            }
            
            return sum
        }
    }
    
    return Matrix(values)
}

func + (lhs: Matrix, rhs: Matrix) -> Matrix {
    guard lhs.dimensions == rhs.dimensions else { fatalError("Incompatable matrix dimensions") }
    
    return lhs.map { val, row, col in val + rhs[row, col] }
}

func relu(_ x: Double) -> Double {
    return max(0, x)
}

func sigmoid(_ x: Double) -> Double {
    return 1 / (1 + exp(-x))
}

struct Brain {
    let snake: Game.Snake
    let game: Game
    
    let weights: [Matrix]
    let biases: [Matrix]
    
    struct Variables {
        let weights: [Matrix]
        let biases: [Matrix]
        
        static func random(_ board: Game.Board) -> Variables {
            let inputSize = 2 + board.width * board.height * 5
            let weights: [Matrix] = [
                .random(rows: inputSize, cols: 16),
                .random(rows: 16, cols: 16),
                .random(rows: 16, cols: 4)
            ]
            let biases: [Matrix] = weights.prefix(weights.count - 1).map {
                .random(rows: 1, cols: $0.dimensions.cols)
            }
            
            return Variables(weights: weights, biases: biases)
        }
        
        func mutated(_ mutationProbablitiy: Double = 0.01) -> Variables {
            let newWeights = weights.map { weightMatrix in
                weightMatrix.map { x in
                    if mutationProbablitiy > .random(in: 0...1) {
                        return .randomNormal()
                    } else {
                        return x
                    }
                }
            }
            
            let newBiases = biases.map { biasMatrix in
                biasMatrix.map { x in
                    if mutationProbablitiy > .random(in: 0...1) {
                        return .randomNormal()
                    } else {
                        return x
                    }
                }
            }
            
            return Variables(weights: newWeights, biases: newBiases)
        }
        
        func offspring(with variables: Variables, mutationProbablitiy: Double = 0.01) -> Variables {
            let newWeights = weights.enumerated().map { (index, weightMatrix) -> Matrix in
                let otherWeights = variables.weights[index]
                
                return weightMatrix.map { val1, row, col in
                    let val2 = otherWeights[row, col]
                    
                    if mutationProbablitiy > 0 && mutationProbablitiy > .random(in: 0...1) {
                        return .randomNormal()
                    }
                    
                    let newValRange = val2 > val1 ? val1...val2 : val2...val1
                    return .random(in: newValRange)
                    
                    /*if (Bool.random()) { return val2 }
                    else { return val1 }*/
                }
            }
            
            let newBiases = biases.enumerated().map { (index, weightMatrix) -> Matrix in
                let otherBiases = variables.biases[index]
                
                return weightMatrix.map { val1, row, col in
                    let val2 = otherBiases[row, col]
                    
                    if mutationProbablitiy > .random(in: 0...1) {
                        return .randomNormal()
                    }
                    
                    if (Bool.random()) { return val2 }
                    else { return val1 }
                }
            }
            
            return Variables(weights: newWeights, biases: newBiases)
        }
        
        func saveToFile(_ filename: String = "model_variables.dat") throws {
            let weightData = weights.flatMap { $0.data }
            let biasData = biases.flatMap { $0.data }
            
            var count = UInt64(weightData.count)
            let weightDataCount = withUnsafeBytes(of: &count, Array.init)
            
            var combinedData = Data()
            combinedData.append(contentsOf: weightDataCount)
            combinedData.append(contentsOf: weightData)
            combinedData.append(contentsOf: biasData)
            
            try combinedData.write(to: URL(fileURLWithPath: filename))
        }
        
        static func readFromFile(_ filename: String = "model_variables.dat") throws -> Variables {
            let combinedData = try Data(contentsOf: URL(fileURLWithPath: filename))
            
            let weightDataCount = Int(combinedData[0...7].withUnsafeBytes { $0.load(as: UInt64.self) })
            
            let weightDataEnd = 8 + weightDataCount
            let weightData = combinedData[8..<weightDataEnd]
            let biasData = combinedData[weightDataEnd..<combinedData.count]
            
            func getMatrices(_ data: Data) -> [Matrix] {
                var data = Data(data)
                
                var matrices: [Matrix] = []
                while !data.isEmpty {
                    var dimensionsData: [UInt32] = [0, 0]
                    _ = dimensionsData.withUnsafeMutableBytes { data[0..<8].copyBytes(to: $0) }
                    
                    let rows = Int(dimensionsData[0])
                    let cols = Int(dimensionsData[1])
                    
                    let byteCount = 8 + rows * cols * 8
                    matrices.append(Matrix(data: data))
                    
                    if byteCount == data.count { break }
                    data = data.advanced(by: byteCount)
                }
                
                return matrices
            }
            
            let weights = getMatrices(weightData)
            let biases = getMatrices(biasData)
            
            return Variables(weights: weights, biases: biases)
        }
    }
    
    var variables: Variables {
        Variables(weights: weights, biases: biases)
    }
    
    init(with variables: Variables, for snake: Game.Snake, in game: Game) {
        self.snake = snake
        self.game = game
        
        self.weights = variables.weights
        self.biases = variables.biases
    }
    
    init(for snake: Game.Snake, in game: Game) {
        self.snake = snake
        self.game = game
        
        let inputSize = 2 + game.board.width * game.board.height * 5
        self.weights = [
            .random(rows: inputSize, cols: 16),
            .random(rows: 16, cols: 16),
            .random(rows: 16, cols: 4)
        ]
        self.biases = weights.prefix(weights.count - 1).map {
            .random(rows: 1, cols: $0.dimensions.cols)
        }
    }
    
    private func getInput() -> [Double] {
        var input: [Double] = []
        let boardInputCount = game.board.width * game.board.height * 5
        input.reserveCapacity(2 + boardInputCount)
        input += [Double(snake.health), Double(snake.length)]
        
        for row in 0...game.board.height - 1 {
            for col in 0...game.board.width - 1 {
                // One-hot for [your head, your body, enemy head, enemy body, food]
                var inputValues: [Double] = [0, 0, 0, 0, 0]
                
                let pos = Game.Board.Positon(x: col, y: row)
                guard let entity = game.boardEntities[pos]?.first else {
                    input += inputValues
                    continue
                }
                
                switch entity {
                case .head(let otherSnake):
                    if otherSnake === snake { inputValues[0] = 1 }
                    else { inputValues[2] = 1 }
                case .body(let otherSnake):
                    if otherSnake === snake { inputValues[1] = 1 }
                    else { inputValues[3] = 1 }
                case .food:
                    inputValues[4] = 1
                default:
                    break
                }
                
                input += inputValues
            }
        }
        
        return input
    }
    
    typealias ScoredMove = (move: Game.Board.Direction, score: Double)
    func getScoredMoves() -> [ScoredMove] {
        let modelInput: Matrix = [
            getInput()
        ]
        
        var output = modelInput
        for (index, weightVals) in weights.enumerated() {
            output = output .* weightVals
            if index == weights.count - 1 { // Last layer
                output = output.map(sigmoid)
            } else {
                output = (output + biases[index]).map(relu)
            }
        }
        
        let scores = output.row(0)
        return Game.Board.Direction.allCases.enumerated().map {
            ($0.element, scores[$0.offset])
        }
    }
    
    static func filterAndSortMoves(_ scoredMoves: [Brain.ScoredMove], for snake: Game.Snake, in game: Game) -> [Brain.ScoredMove] {
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
    
    static func okMoves(for snake: Game.Snake, in game: Game) -> [Game.Board.Direction] {
        let filtered = Game.Board.Direction.allCases.filter { move in
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
        
        return filtered
    }
}
