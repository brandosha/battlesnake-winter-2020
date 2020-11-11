export interface GameData {
  game:  Game;
  turn:  number;
  board: Board;
  you:   Snake;
}

export interface Board {
  height:  number;
  width:   number;
  snakes:  Snake[];
  food:    Point[];
  hazards: any[];
}

export interface Point {
  x: number;
  y: number;
}

export interface Snake {
  id:      string;
  name:    string;
  latency: string;
  health:  number;
  body:    Point[];
  head:    Point;
  length:  number;
  shout:   string;
}

export interface Game {
  id:      string;
  ruleset: Ruleset;
  timeout: number;
}

export interface Ruleset {
  name:    string;
  version: string;
}

export as namespace BattleSnake