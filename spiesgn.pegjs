/* TwoSpies game notation grammar */

/* Example:

Bifocal/0v0/2nd/Vie/Bru
Ams-10/Bru m,m
N/Vie mWar,S!

*/

file
  = NL* first:game rest:(NLNL @game)* NL* {
  		return [first, ...rest]
    }

NL "newline" = ([ \r]? "\n" [ \t]*)+

NLNL "empty line" = ([ \r]? "\n" [ \t]*) NL

ws "whitespace(optional)" = [ \t]*

_ "divider" = [ /()]+

number "number"
  = [0-9]+ { return parseInt(text()) }

game
  = game:gameStart lines:(NL @line)+ {
      game.turns = lines
      return game
    }

gameStart
  = map:$[a-z .']i+ _ score:(@score _)? startPlayer:startPlayer players:(_ @players)? {
      let p1Starts = (startPlayer[0] == '1' || startPlayer == 'F')
  	  var result = {map: map, startPlayerNum: (p1Starts ? 1 : 2)}

	  Object.assign(result, score)
      Object.assign(result, players)

      return result
    }

startPlayer
  = '1st' / '2nd' / [SF]

score "score (e.g. 2v2)"
  = p1Score:number ('v'/'-') p2Score:number {
  	  return { p1Score: p1Score, p2Score: p2Score }
  	}

players
  = p1Spawn:city _ p2Spawn:city {
    return { p1Spawn: p1Spawn, p2Spawn: p2Spawn }
  }

playerDefs
  = p1:playerDef _ p2:playerDef {
      p1.playerNum = 1
      p2.playerNum = 2
      return {p1: p1, p2: p2}
    }

playerDef
  = name:$[^0-9/]* ws startLocation:city {
      return {name: name, startLocation: startLocation}
    }

line
  = before:(@event _)? turn:turn after:(_ @event)? {
  	  var res = {}
      if (before) { res.before = before }
      Object.assign(res, turn)
      if (after) { res.after = after }
  	  return res
    }
  / event

event "event"
  = city:city ws '-' ws value:(number / 'A') {
      if (value == 'A') {
      	return {bonusAction: city}
      } else {
      	value = parseInt(value)
        if (!Number.isInteger(value) && value >= 0) {
          expected('a number of turns, amount of intel, or "A"')
        } else if (value > 4) {
          return {intel: value, in: city}
        } else {
          return {closing: city, turns: value}
        }
      }
    }
  / 'N' &('/' / NL) { return undefined }

turn
  = location:location?reveal:'!'? _ action:action actions:(',' ws @action)* {
  	  if (reveal) {
      	return {playerLocation: location, reveal: location, actions: [action, ...actions]}
      } else {
      	return {playerLocation: location, actions: [action, ...actions]}
      }
    }

action
  = action:actionAbbr city:('-'? @location)? reveal:('!' city?)? {
      if (city && city != '?') {
        action = {[action]: city}
        if (reveal) {
          action.reveal = reveal[1] ?? ''
        }
      } else if (reveal) {
        reveal = reveal[1] ?? ''
        city ??= (action == 'move') ? reveal : ''
        action = {[action]: city, reveal: reveal ?? ''}
      } else if (action == 'move') {
        action = 'moveOrWait'
      }
      return action
    }

actionAbbr "action code"
  = 'M'i { return 'move' }
  / 'W'i { return 'wait' }
  / 'C'i { return 'control' }
  / '+'i { return 'control' }
  / 'SR'i { return 'strikeReportsUnlocked' }
  / 'U'i { return 'strikeReportsUnlocked' }
  / 'S'i { return 'strike' }
  / 'K'i { return 'strike' }
  / 'L'i { return 'locate' }
  / 'E'i { return 'encryptionUnlocked' }
  / 'RR'i { return 'rapidReconUnlocked' }
  / 'R'i { return 'rapidReconUnlocked' }
  / 'D'i { return 'goDeep' }
  / 'GD'i { return 'goDeep' }
  / 'P'i { return 'prep' }
  / '?'i { return 'encryptedAction' }
  / 'X'i { return 'encryptedAction' }

// reveal
//   = '!' ws city:city? {
//       return { reveal: city ?? '' }
//     }

control
  = 'C'i city:('-'? @city) {
      return {control: city}
    }

location "location" = city / '?' / '_?_'

city "city"
  = @city:cityName ! { return city === undefined } // this is a workaround for not being able to fail a match in the action

cityName
  = str: $([a-z]i [a-z]i [a-z]i+) {
      const CITIES = {
    par: "Paris",
    lon: "London",
    bru: "Brussels",
    mon: "Monaco",
    gen: "Geneva",
    ams: "Amsterdam",
    ven: "Venice",
    rom: "Rome",
    ber: "Berlin",
    vie: "Vienna",
    sto: "Stockholm",
    bud: "Budapest",
    bel: "Belgrade",
    war: "Warsaw",
    kie: "Kiev",
    ist: "Istanbul",
    mos: "Moscow"
      }
      str = str.slice(0,3).toLowerCase()
      return CITIES[str]
    }
