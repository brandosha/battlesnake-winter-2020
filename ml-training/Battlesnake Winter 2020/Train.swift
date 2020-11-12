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
        
        let game = Game(snakes: [Game.Snake(), Game.Snake()])
        
        var stepsPlayed = 0
        
        game.printBoard()
        while game.remainingSnakes > 1 {
            if (Bool.random()) {
                game.food.insert(.random(in: game.board))
            }
            game.doMoves { snake, game in
                let allMoves: [Game.Board.Direction] = [.up, .down, .left, .right]
                
                let okMoves = allMoves.filter { move in
                    let newPos = move.appliedTo(snake.head)
                    
                    if !(0...game.board.width - 1 ~= newPos.x) { return false }
                    if !(0...game.board.height - 1 ~= newPos.y) { return false }
                    
                    guard let boardEntity = game.boardDict[newPos] else { return true }
                    
                    switch boardEntity {
                    case .food:
                        return true
                    default:
                        return false
                    }
                }
                
                return okMoves.randomElement() ?? .random()
            }
            usleep(100 * 1000)
            game.printBoard()
            
            stepsPlayed += 1
        }
        
        print("Steps played: \(stepsPlayed)")
    }
}
