//
//  Game.swift
//  Battlesnake Winter 2020
//
//  Created by Brandon Lantz on 11/11/20.
//

import Foundation

class Game {
    
    struct Board {
        let width, height: Int
        
        static let standard = Board(width: 11, height: 11)
        
        struct Positon: Hashable {
            var x, y: Int
            
            static func random(in board: Board) -> Positon {
                return Positon(
                    x: .random(in: 0...board.width - 1),
                    y: .random(in: 0...board.height - 1)
                )
            }
        }
        
        enum Direction {
            case up, down, left, right
            
            static func random() -> Direction {
                let all: [Direction] = [.up, .down, .left, .right]
                return all.randomElement()!
            }
            
            func appliedTo(_ position: Positon) -> Positon {
                var xVal = position.x
                var yVal = position.y
                
                switch self {
                case .up:
                    yVal += 1
                case .down:
                    yVal -= 1
                case .left:
                    xVal -= 1
                case .right:
                    xVal += 1
                }
                
                return Positon(x: xVal, y: yVal)
            }
        }
    }
    
    class Snake {
        var facing: Board.Direction = .random()
        var head: Board.Positon
        var body: [Board.Positon]
        var isAlive: Bool = true
        var id: String = {
            let chars = "0123456789abcdefghijklmnopqrstuvwxyz"
            return String((0...16).map { _ in chars.randomElement()! })
        }()
        
        let bodyString = String("HXZN".randomElement()!)
        let headString = String("@0¢".randomElement()!)
        
        init(
            board: Board = .standard,
            head: Board.Positon? = nil,
            length: Int = 3
        ) {
            self.head = head ?? .random(in: board)
            self.body = .init(repeating: self.head, count: 3)
        }
        
        func move(_ direction: Board.Direction) {
            self.head = direction.appliedTo(self.head)
            
            self.body.insert(self.head, at: 0)
            self.body.removeLast()
        }
    }
    
    let board: Board
    let snakes: [Snake]
    var food: Set<Board.Positon> = []
    var remainingSnakes: Int
    
    init(_ board: Board = .standard, snakes: [Snake]) {
        self.board = board
        self.snakes = snakes
        self.remainingSnakes = snakes.count
    }
    
    func doMoves(selectMove: (Snake, Game) -> Board.Direction) {
        for snake in snakes {
            guard snake.isAlive else { continue }
            
            let move = selectMove(snake, self)
            snake.move(move)
            
            if (
                !(0...self.board.width - 1 ~= snake.head.x) ||
                !(0...self.board.height - 1 ~= snake.head.y)
            ) {
                snake.isAlive = false
                remainingSnakes -= 1
            } else if food.contains(snake.head) {
                food.remove(snake.head)
                snake.body.append(snake.body.last!)
            }
        }
        
        var snakeBodies: Dictionary<Board.Positon, (snake: Snake, isHead: Bool)> = [:]
        for snake in snakes {
            guard snake.isAlive else { continue }
            
            for (index, bodySegment) in snake.body.enumerated() {
                let isHead = index == 0
                if let collidedWith = snakeBodies[bodySegment] {
                    if collidedWith.isHead {
                        collidedWith.snake.isAlive = false
                        remainingSnakes -= 1
                    }
                    if isHead {
                        snake.isAlive = false
                        remainingSnakes -= 1
                    }
                } else {
                    snakeBodies[bodySegment] = (snake, isHead)
                }
            }
        }
        // cachedSnakeBodies = snakeBodies
        
        boardDict = getBoardDict()
    }
    
    /*private lazy var cachedSnakeBodies: Dictionary<Board.Positon, (snake: Snake, isHead: Bool)> = {
        var snakeBodies: Dictionary<Board.Positon, (snake: Snake, isHead: Bool)> = [:]
        for snake in snakes {
            guard snake.isAlive else { continue }
            
            for (index, bodySegment) in snake.body.enumerated() {
                let isHead = index == 0
                if snakeBodies[bodySegment] != nil && isHead {
                    snakeBodies[bodySegment] = (snake, isHead)
                } else {
                    snakeBodies[bodySegment] = (snake, isHead)
                }
            }
        }
        
        return snakeBodies
    }()*/
    
    enum Entity {
        case head(Snake)
        case body(Snake)
        case food
    }
    
    lazy var boardDict: Dictionary<Board.Positon, Entity?> = {
        return getBoardDict()
    }()
    
    private func getBoardDict() -> Dictionary<Board.Positon, Entity?> {
        var boardDict: Dictionary<Board.Positon, Entity?> = [:]
        
        for foodPos in food {
            boardDict[foodPos] = .food
        }
        
        for snake in snakes {
            for bodySegment in snake.body {
                if bodySegment == snake.head {
                    boardDict[bodySegment] = .head(snake)
                } else {
                    boardDict[bodySegment] = .body(snake)
                }
            }
        }
        
        return boardDict
    }
    
    func printBoard() {
        var textRows: [String] = [.init(repeating: "-", count: board.width + 2)]
        for row in 0...board.height - 1 {
            var textRow: String = "|"
            for col in 0...board.width - 1 {
                let pos = Board.Positon(x: col, y: row)
                
                switch boardDict[pos] {
                case .body(let snake):
                    if snake.isAlive { textRow += snake.bodyString }
                    else { textRow += " " }
                case .head(let snake):
                    if snake.isAlive { textRow += snake.headString }
                    else { textRow += " " }
                case .food:
                    textRow += "*"
                default:
                    textRow += " "
                }
                
                /*if let bodyPart = cachedSnakeBodies[pos] {
                    if (bodyPart.isHead) {
                        textRow += "@"
                    } else {
                        textRow += "#"
                    }
                } else if food.contains(pos) {
                    textRow += "*"
                } else {
                    textRow += " "
                }*/
            }
            
            textRow += "|"
            textRows.append(textRow)
        }
        textRows.append(.init(repeating: "-", count: board.width + 2))
        
        print(textRows.joined(separator: "\n"))
    }
    
}
