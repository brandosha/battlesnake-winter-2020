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
        
        let board = Game.Board(width: 7, height: 7)
        let game = Game(board: board, snakes: [Game.Snake(in: board)])
        // let maxLength = game.board.width * game.board.height
        
        var stepsPlayed = 0
        
        var soloRound = 0
        
        game.printBoard()
        while game.remainingSnakes > 0 {
            game.addFood()
            
            game.doMoves { snake, _ in
                let pos = snake.head
                let evenRow = pos.y % 2 == 0
                let evenCol = pos.x % 2 == 0
                
                // print(pos, evenRow, evenCol)
                
                /*if snake.length == maxLength - 2 && pos == .init(x: 0, y: 1) {
                    return .down
                }*/
                
                if pos.x == 0 {
                    if pos.y == game.board.height - 1 { return .right }
                    else { return .up }
                } else if pos.y == 1 {
                    if evenCol { return .down }
                    else { return .left }
                } else if pos.y == 0 {
                    if evenCol { return .left }
                    else if pos.x == 1  {
                        soloRound += 1
                        if soloRound % 2 == 1 { return .left }
                        else { return .up }
                    }
                    else { return .up }
                } else if pos.x == game.board.width - 1 {
                    if evenRow { return .down }
                    else { return .left }
                } else if pos.x == 1 {
                    if evenRow { return .right }
                    else { return .down }
                }
                
                if evenRow { return .right }
                else { return .left }
            }
            
            /*game.doMoves { snake, game in
                let allMoves: [Game.Board.Direction] = [.up, .down, .left, .right]
                
                let okMoves = allMoves.filter { move in
                    let newPos = move.appliedTo(snake.head)
                    
                    if !(0...game.board.width - 1 ~= newPos.x) { return false }
                    if !(0...game.board.height - 1 ~= newPos.y) { return false }
                    
                    guard let boardEntity = game.boardEntities[newPos]?.first else { return true }
                    
                    switch boardEntity {
                    case .potential(let otherSnake):
                        return !otherSnake.isAlive || otherSnake === snake || otherSnake.length < snake.length
                    case .head(let otherSnake):
                        return !otherSnake.isAlive
                    case .body(let otherSnake) where !otherSnake.isAlive:
                        return true
                    case .food:
                        return true
                    default: return false
                    }
                }
                
                if okMoves.isEmpty { return .random() }
                
                let movesOrderedByValue = okMoves.sorted {
                    let newPos = [$0, $1].map { $0.appliedTo(snake.head) }
                    
                    let dist = newPos.map {
                        sqrt(
                            pow((Double($0.x) - Double(game.board.width) / 2), 2) +
                            pow((Double($0.y) - Double(game.board.height) / 2), 2)
                        )
                    }
                    
                    return dist[0] < dist[1]
                }
                
                let index = Int(floor(pow(Double.random(in: 0..<1), 2) * Double(okMoves.count)))
                return movesOrderedByValue[index]
            }*/
            usleep(100 * 1000)
            game.printBoard()
            
            stepsPlayed += 1
        }
        
        print("Steps played: \(stepsPlayed)")
    }
}
