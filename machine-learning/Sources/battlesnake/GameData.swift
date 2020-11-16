//
//  GameData.swift
//  Battlesnake Winter 2020
//
//  Created by Brandon Lantz on 11/11/20.
//

import Foundation

struct GameData: Codable {
    let game: Info
    let turn: Int
    let board: Board
    let you: Snake
    
    struct Info: Codable {
        let id: String
        let ruleset: Ruleset
        let timeout: Int
    }
    
    struct Ruleset: Codable {
        let name, version: String
    }
    
    struct Board: Codable {
        let height, width: Int
        let snakes: [Snake]
        let food, hazards: [Position]
        
        struct Position: Codable {
            let x, y: Int
        }
    }

    struct Snake: Codable {
        let id, name, latency: String
        let health: Int
        let body: [Board.Position]
        let head: Board.Position
        let length: Int
        let shout: String
    }
}

