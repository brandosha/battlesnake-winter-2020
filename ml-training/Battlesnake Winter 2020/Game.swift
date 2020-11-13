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
        
        enum Direction: CaseIterable {
            case up, down, left, right
            
            static func random() -> Direction {
                return Direction.allCases.randomElement()!
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
        var head: Board.Positon
        var body: [Board.Positon]
        var isAlive: Bool = true
        
        let id: String = {
            let chars = "0123456789abcdefghijklmnopqrstuvwxyz"
            return String((0...16).map { _ in chars.randomElement()! })
        }()
        let bodyString = String("HXZN".randomElement()!)
        let headString = String("@0¢".randomElement()!)
        
        var length: Int { body.count }
        
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
    
    func addFood() {
        if !food.isEmpty && 0.15 < .random(in: 0..<1) { return }
        
        var openSpaces: [Board.Positon] = []
        
        for row in 0...board.height - 1 {
            for col in 0...board.width - 1 {
                let pos = Board.Positon(x: col, y: row)
                
                if boardEntities[pos] == nil {
                    openSpaces.append(pos)
                }
            }
        }
        
        if !openSpaces.isEmpty {
            food.insert(openSpaces.randomElement()!)
        }
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
        
        boardEntities = setBoardEntities(applyCollisionRules: true)
    }
    
    enum Entity {
        case head(Snake)
        case body(Snake)
        case potential(Snake)
        case food
        
        enum Case {
            case head, body, potential, food
        }
        
        var `case`: Case {
            switch self {
            case .head: return .head
            case .body: return .body
            case .potential: return .potential
            case .food: return.food
            }
        }
    }
    
    lazy private(set) var boardEntities: Dictionary<Board.Positon, [Entity]> = {
        return setBoardEntities()
    }()
    
    private func hideDeadSnake(_ snake: Snake) {
        remainingSnakes -= 1
        
        for bodySegment in snake.body {
            guard let entities = boardEntities[bodySegment] else { continue }
            
            rotating: for _ in 1...entities.count {
                let top = entities.first!
                switch top {
                case .head(let s) where s === snake, .body(let s) where s === snake:
                    boardEntities[bodySegment] = entities.suffix(from: 1) + [top]
                default:
                    break rotating
                }
            }
        }
    }
    
    private func handleCollision(_ a: Entity, _ b: Entity) {
        switch (a, b) {
        case (.head(let snakeA), .head(let snakeB)),
             (.body(let snakeA), .head(let snakeB)),
             (.head(let snakeA), .body(let snakeB)):
            if !snakeA.isAlive || !snakeB.isAlive { return }
        default:
            break
        }
        
        switch (a, b) {
        case (.head(let snakeA), .head(let snakeB)):
            if snakeA.length >= snakeB.length {
                snakeB.isAlive = false
                hideDeadSnake(snakeB)
            } else {
                snakeA.isAlive = false
                hideDeadSnake(snakeA)
            }
        case (.head(let snake), .body):
            snake.isAlive = false
            hideDeadSnake(snake)
        case (.body, .head(let snake)):
            snake.isAlive = false
            hideDeadSnake(snake)
        default:
            break
        }
    }
    
    private func setBoardEntities(applyCollisionRules: Bool = false) -> Dictionary<Board.Positon, [Entity]> {
        // var boardEntities: Dictionary<Board.Positon, [Entity]> = [:]
        boardEntities = [:]
        
        for foodPos in food {
            boardEntities[foodPos] = [.food]
        }
        
        let sortedSnakes = snakes.sorted(by: {
            if ($0.isAlive == $1.isAlive) { return false }
            else { return $1.isAlive }
        })
        for snake in sortedSnakes {
            for (index, bodySegment) in snake.body.enumerated() {
                var entity: Entity
                
                let isHead = index == 0
                if isHead {
                    entity = .head(snake)
                } else {
                    entity = .body(snake)
                }
                
                if let collisionEntity = boardEntities[bodySegment]?.first {
                    let sharingEntities = boardEntities[bodySegment]!
                    
                    if snake.isAlive {
                        if entity.case == .head {
                            boardEntities[bodySegment]?.insert(entity, at: 0)
                        } else {
                            var insertIndex = 0
                            indexIncrement: for entity in sharingEntities {
                                switch entity {
                                case .head(let otherSnake) where otherSnake.isAlive:
                                    insertIndex += 1
                                default:
                                    break indexIncrement
                                }
                            }
                            
                            boardEntities[bodySegment]?.insert(entity, at: insertIndex)
                        }
                    } else {
                        boardEntities[bodySegment]?.append(entity)
                        /*if entity.case == .head {
                            var insertIndex = sharingEntities.count - 1
                            decrementIndex: for entity in sharingEntities.reversed() {
                                switch entity {
                                case .body(let otherSnake) where !otherSnake.isAlive:
                                    insertIndex -= 1
                                default:
                                    break decrementIndex
                                }
                            }
                            
                            boardEntities[bodySegment]?.insert(entity, at: insertIndex)
                        } else {
                            boardEntities[bodySegment]?.append(entity)
                        }*/
                    }
                    
                    if !applyCollisionRules || !snake.isAlive { continue } // Ignore collision rules
                    
                    handleCollision(entity, collisionEntity)
                } else {
                    boardEntities[bodySegment] = [entity]
                }
            }
        }
        
        for snake in snakes {
            if !snake.isAlive { continue }
            
            for potentialMove in Board.Direction.allCases {
                let potentialPos = potentialMove.appliedTo(snake.head)
                
                if boardEntities[potentialPos] == nil {
                    boardEntities[potentialPos] = [.potential(snake)]
                } else {
                    boardEntities[potentialPos]?.append(.potential(snake))
                }
            }
        }
        
        return boardEntities
    }
    
    func printBoard() {
        var textRows: [String] = [.init(repeating: "-", count: board.width * 3 + 2)]
        for row in (0...board.height - 1).reversed() {
            var textRow: String = "|"
            for col in 0...board.width - 1 {
                let pos = Board.Positon(x: col, y: row)
                
                switch boardEntities[pos]?.first {
                case .body(let snake) where snake.isAlive:
                    textRow += " \(snake.bodyString) "
                case .head(let snake) where snake.isAlive:
                    textRow += " \(snake.headString) "
                case .food:
                    textRow += " * "
                default:
                    textRow += "   "
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
        textRows.append(.init(repeating: "-", count: board.width * 3 + 2))
        
        print(textRows.joined(separator: "\n"))
    }
    
}
