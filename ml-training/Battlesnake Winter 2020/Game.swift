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
        
        struct Positon {
            let x, y: Int
            
            static func random(in board: Board) -> Positon {
                return Positon(
                    x: .random(in: 0...board.width - 1),
                    y: .random(in: 0...board.height - 1)
                )
            }
        }
    }
    
    class Snake {
        let head: Board.Positon
        let body: [Board.Positon]
        
        init(
            board: Board = Board(width: 11, height: 11),
            head: Board.Positon? = nil,
            length: Int = 3
        ) {
            self.head = head ?? .random(in: board)
            self.body = .init(repeating: self.head, count: 3)
        }
    }
    
    let board: Board
    let snakes: [Snake]
    
    init(_ board: Board, snakes: [Snake]) {
        self.board = board
        self.snakes = snakes
    }
}
