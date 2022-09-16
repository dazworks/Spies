// TwoSpies map description grammar

start
  = _? first:line _? rest:("\n" _? @line _?)* {
  		return [first, ...rest]
    }

line
  = list
  / road
  / closing
  / &_

list
  = head:city tail:("," _ @city)+ {
  		return [head, ...tail];
    }

road
  = from: city _ "-" _ to: city

closing
  = 'closed' city
  / 'closed' list

_ "whitespace" = [ \t\r]*

city
  = str: $[a-z]i+ &[^a-z] {
      const CITIES = [
        "Paris",
        "London",
        "Brussels",
        "Monaco",
        "Geneva",
        "Amsterdam",
        "Venice",
        "Rome",
        "Berlin",
        "Vienna",
        "Stockholm",
        "Budapest",
        "Belgrade",
        "Warsaw",
        "Kiev",
        "Istanbul",
        "Moscow"
      ]
      str = str.toLowerCase()
      var match = null
      for (let c of CITIES) {
        if (c.toLowerCase().startsWith(str)) {
          if (match) {
            return 'a'
          } else {
            match = c
          }
        }
      }
      return match
    }