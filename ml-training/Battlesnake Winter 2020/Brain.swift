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
    
    private init (values: [[Double]], rows: Int, cols: Int) {
        self.values = values
        self.dimensions = (rows, cols)
    }
    
    static func random(rows: Int, cols: Int, range: ClosedRange<Double> = -1...1) -> Matrix {
        let values = (1...rows).map { _ in
            (1...cols).map { _ in
                Double.random(in: range)
            }
        }
        
        return Matrix(values)
    }
    
    static func random(_ dimensions: Dimensions, range: ClosedRange<Double> = -1...1) -> Matrix {
        return .random(rows: dimensions.rows, cols: dimensions.cols, range: range)
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
    // let layers: [(weights: Matrix, biases: Matrix)]
    
    init(for snake: Game.Snake, in game: Game) {
        self.snake = snake
        self.game = game
        
        let initRange = -0.1...0.1
        let inputSize = 2 + game.board.width * game.board.height * 5
        self.weights = [
            .random(rows: inputSize, cols: 16, range: initRange),
            .random(rows: 16, cols: 16, range: initRange),
            .random(rows: 16, cols: 4, range: initRange)
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
    
    func scoreMoves() -> [(move: Game.Board.Direction, score: Double)] {
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
}
