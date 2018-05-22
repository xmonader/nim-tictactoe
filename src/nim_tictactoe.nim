import sequtils, tables, strutils, strformat, random, os, parseopt2

randomize()

let NEXT_PLAYER = {"X":"O", "O":"X"}.toTable

type 
  Board = ref object of RootObj
    list: seq[string]

let WINS = @[ @[0,1,2], @[3,4,5], @[6,7,8], @[0, 3, 6], @[1,4,7], @[2,5,8], @[0,4,8], @[2,4,6] ]

proc newBoard(): Board =
  var b = Board()
  b.list = @["0", "1", "2", "3", "4", "5", "6", "7", "8"]
  return b

proc done(this: Board): (bool, string) =
    for w in WINS:
        if this.list[w[0]] == this.list[w[1]] and this.list[w[1]]  == this.list[w[2]]:
          if this.list[w[0]] == "X":
            return (true, "X")
          elif this.list[w[0]] == "O":
            return (true, "O")
    if all(this.list, proc(x:string):bool = x in @["O", "X"]) == true:
        return (true, "tie")
    else:
        return (false, "going")

proc `$`(this:Board): string =
  let rows: seq[seq[string]] = @[this.list[0..2], this.list[3..5], this.list[6..8]]
  for row  in rows:
    for cell in row:
      stdout.write(cell & " | ")
    echo("\n--------------")

proc emptySpots(this:Board):seq[int] =
    var emptyindices = newSeq[int]()
    for i in this.list:
      if i.isDigit():
        emptyindices.add(parseInt(i))
    return emptyindices

type 
  Move = tuple[score:int, idx:int]

proc `<`(a,b: Move): bool =
  return a.score < b.score

type
  Game = ref object of RootObj
    currentPlayer*: string
    board*: Board
    aiPlayer*: string
    difficulty*: int


proc newGame(aiPlayer:string="", difficulty:int=9): Game =
  var
    game = new Game

  game.board = newBoard()
  game.currentPlayer = "X"
  game.aiPlayer = aiPlayer
  game.difficulty = difficulty
  
  return game
        # 0 1 2
        # 3 4 5
        # 6 7 8 

proc changePlayer(this:Game) : void =
  this.currentPlayer = NEXT_PLAYER[this.currentPlayer]   
    
    
proc getBestMove(this: Game, board: Board, player:string): Move =
        let (done, winner) = board.done()
        if done == true:
            if winner ==  this.aiPlayer:
                return (score:10, idx:0)
            elif winner != "tie": #human
                return (score:(-10), idx:0)
            else:
                return (score:0, idx:0)
            
        let empty_spots = board.empty_spots()
        # print("EMPTY INDICES: ", empty_spots)
        var moves = newSeq[Move]() 
        for idx in empty_spots:
            var newboard = newBoard()

            newboard.list = map(board.list, proc(x:string):string=x)
            newboard.list[idx] = player
            let score = this.getBestMove(newboard, NEXT_PLAYER[player]).score
            let idx = idx
            let move = (score:score, idx:idx)
            moves.add(move)
        
        if player == this.aiPlayer:
          return max(moves)          
          # var bestScore = -1000
          # var bestMove: Move 
          # for m in moves:
          #   if m.score > bestScore:
          #     bestMove = m
          #     bestScore = m.score
          # return bestMove
        else:
          return min(moves)          
          # var bestScore = 1000
          # var bestMove: Move 
          # for m in moves:
          #   if m.score < bestScore:
          #     bestMove = m
          #     bestScore = m.score
          # return bestMove

proc startGame*(this:Game): void=
    while true:
        echo this.board
        if this.aiPlayer != this.currentPlayer:
          stdout.write("Enter move: ")
          let move = stdin.readLine()
          this.board.list[parseInt($move)] = this.currentPlayer
        else:
            if this.currentPlayer == this.aiPlayer:
              let emptyspots = this.board.emptySpots()
              if len(emptyspots) <= this.difficulty:
                  echo("AI MOVE..")
                  let move = this.getbestmove(this.board, this.aiPlayer)
                  this.board.list[move.idx] = this.aiPlayer
              else:
                  echo("RANDOM GUESS")
                  this.board.list[emptyspots.rand()] = this.aiPlayer
  
        this.change_player()
        let (done, winner) = this.board.done()

        if done == true:
          echo this.board
          if winner == "tie":
              echo("TIE")
          else:
              echo("WINNER IS :", winner )
          break           


proc writeHelp() = 
  echo """
TicTacToe 0.1.0 (MinMax version)
Allowed arguments:
  -h | --help         : show help
  -a | --ai           : AI player [X or O]
  -l | --difficulty   : destination to stow to
  """

proc cli*() =
  var 
    aiplayer = ""
    difficulty = 9

  for kind, key, val in getopt():
    case kind
    of cmdLongOption, cmdShortOption:
        case key
        of "help", "h": 
            writeHelp()
            quit()
        of "aiplayer", "a":
          echo "AIPLAYER: " & val
          aiplayer = val
        of "level", "l": difficulty = parseInt(val)
        else:
          discard
    else:
      discard 

  let g = newGame(aiPlayer=aiplayer, difficulty=difficulty)
  g.startGame()

when isMainModule:
  cli()