const bodyParser = require('body-parser')
const express = require('express')

const PORT = process.env.PORT || 3000

const VERBOSE = true

const app = express()
app.use(bodyParser.json())

app.get('/', handleIndex)
app.post('/start', handleStart)
app.post('/move', handleMove)
app.post('/end', handleEnd)

app.listen(PORT, () => console.log(`Battlesnake Server listening at http://127.0.0.1:${PORT}`))


function handleIndex(request, response) {
  var battlesnakeInfo = {
    apiversion: '1',
    author: 'brandosha',
    color: '#0345fc',
    head: 'sand-worm',
    tail: 'bolt'
  }
  response.status(200).json(battlesnakeInfo)
}

function handleStart(request, response) {
  var gameData = request.body

  console.log('START')
  response.status(200).send('ok')
}

/** 
 * @param { BattleSnake.Snake } snake
 * @param { BattleSnake.Board } board
 * */
function surviveAlone(snake, board) {
  let pos = snake.head
  let evenRow = pos.y % 2 == 0
  let evenCol = pos.x % 2 == 0
  
  if (pos.x == 0) {
    if (pos.y == board.height - 1) { return 'right' }
    else { return 'up' }
  } else if (pos.y == 1) {
    if (evenCol) { return 'down' }
    else { return 'left' }
  } else if (pos.y == 0) {
    if (evenCol) { return 'left' }
    else { return 'up' }
  } else if (pos.x == board.width - 1) {
    if (evenRow) { return 'down' }
    else { return 'left' }
  } else if (pos.x == 1) {
    if (evenRow) { return 'right' }
    else { return 'down' }
  }
  
  if (evenRow) { return 'right' }
  else { return 'left' }
}

function handleMove(request, response) {
  /** @type { BattleSnake.GameData } */
  const gameData = request.body

  if (gameData.board.snakes.length == 1) {
    const maxGameLength = 1000

    if (gameData.turn > maxGameLength) return 'down'
    else return surviveAlone(gameData.you)
  }

  /** @type { ['up', 'down', 'left', 'right'] } */
  const possibleMoves = ['up', 'down', 'left', 'right']
  const moveVecs = {
    up: { x: 0, y: 1 },
    down: { x: 0, y: -1 },
    left: { x: -1, y: 0 },
    right: { x: 1, y: 0 }
  }

  const posStr = (pos) => [pos.x, pos.y].join(',')

  const badPoints = {}
  gameData.board.snakes.forEach(snake => {
    snake.body.slice(0, -1).forEach(pos => {
      badPoints[posStr(pos)] = true
    })

    if (snake.id == gameData.you.id) return

    possibleMoves.forEach(move => {
      const newHeadPos = {
        x: snake.head.x + moveVecs[move].x,
        y: snake.head.y + moveVecs[move].y
      }

      badPoints[posStr(newHeadPos)] = true
    })
  })
  gameData.board.hazards.forEach(hazard => {
    badPoints[posStr(hazard)] = true
  })

  if (VERBOSE) console.log('current position', gameData.you.head)

  var okMoves = possibleMoves.filter(move => {
    const moveVec = moveVecs[move]
    const newPos = {
      x: gameData.you.head.x + moveVec.x,
      y: gameData.you.head.y + moveVec.y
    }

    if (newPos.x >= gameData.board.width || newPos.x < 0) {
      if (VERBOSE) console.log("can't move " + move + ': outside board')
      return false
    }
    if (newPos.y >= gameData.board.width || newPos.y < 0) {
      if (VERBOSE) console.log("can't move " + move + ': outside board')
      return false
    }

    if (badPoints[posStr(newPos)] == true) {
      if (VERBOSE) console.log("can't move " + move + ': spot occupied')
      return false
    }

    return true
  })

  // Sort moves by resultant distance from center
  okMoves.sort((move1, move2) => {
    const pos = [move1, move2].map(move => {
      const moveVec = moveVecs[move]
      const newPos = {
        x: gameData.you.head.x + moveVec.x,
        y: gameData.you.head.y + moveVec.y
      }

      return newPos
    })

    const dist = pos.map(pos => {
      return Math.sqrt(
        Math.pow(pos.x - gameData.board.width / 2, 2) +
        Math.pow(pos.y - gameData.board.height / 2, 2)
      )
    })

    return dist[0] - dist[1]
  })

  if (VERBOSE) console.log('selecting move from', okMoves)

  let index = Math.random()
  index = Math.floor(index * index * okMoves.length)

  const randFrom = (array) => array[Math.floor(Math.random() * array.length)]
  const move = okMoves[index] || randFrom(possibleMoves)

  console.log('MOVE: ' + move)
  response.status(200).send({
    move: move
  })
}

function handleEnd(request, response) {
  var gameData = request.body

  console.log('END')
  response.status(200).send('ok')
}
