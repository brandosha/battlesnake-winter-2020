const bodyParser = require('body-parser')
const express = require('express')

const PORT = process.env.PORT || 3000

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
    author: '',
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

function handleMove(request, response) {
  /** @type { BattleSnake.GameData } */
  var gameData = request.body

  var possibleMoves = ['up', 'down', 'left', 'right']
  const moveVecs = {
    up: { x: 0, y: 1 },
    down: { x: 0, y: -1 },
    left: { x: -1, y: 0 },
    right: { x: 1, y: 0 }
  }

  var okMoves = possibleMoves.filter(move => {
    const moveVec = moveVecs[move]
    const newPos = {
      x: gameData.you.head.x + moveVec.x,
      y: gameData.you.head.y + moveVec.y
    }

    return gameData.board.snakes.every(snake => {
      return snake.body.every(point => {
        return point.x != newPos.x && point.y != newPos.y
      })
    })
  })

  var move = okMoves[Math.floor(Math.random() * okMoves.length)]

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
