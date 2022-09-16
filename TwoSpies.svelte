<script>
	import Konva from 'konva@8/lib/Core'
  import { Circle } from "konva/lib/shapes/Circle";
 	import { Text } from "konva/lib/shapes/Text";
 	import { Rect } from "konva/lib/shapes/Rect";
	import { Line } from "konva/lib/shapes/Line";

	import {onMount} from 'svelte'

	// Svelte bindings
	let container
	let newCityName
	var codeTextField = ''

	const CONF = {
		cityRadius: 9,
		mapColor: '#f7f4e9',
		mapWidth: 800,
		mapHeight: 700,
		cityColor: 'gray',
		selectedCityColor: 'black',
	}

	let STATE = {
		selectedCity: null
	}

	let CITIES = {
		par: new City({name: "Paris", x:69, y:371, labelX:-1, labelY:12}),
		lon: new City({name: "London", x:81, y:254, labelX:-1, labelY:12}),
		bru: new City({name: "Brussels", x:159, y:337, labelX:-1, labelY:12}),
		mon: new City({name: "Monaco", x:172, y:515, labelX:-1, labelY:12}),
		gen: new City({name: "Geneva", x:186, y:424, labelX:-1, labelY:12}),
		ams: new City({name: "Amsterdam", x:209, y:248, labelX:-1, labelY:12}),
		ven: new City({name: "Venice", x:302, y:493, labelX:-1, labelY:12}),
		rom: new City({name: "Rome", x:320, y:586, labelX:-1, labelY:12}),
		ber: new City({name: "Berlin", x:323, y:294, labelX:-1, labelY:12}),
		sto: new City({name: "Stockholm", x:383, y:67, labelX:-1, labelY:12}),
		vie: new City({name: "Vienna", x:384, y:422, labelX:-1, labelY:12}),
		bud: new City({name: "Budapest", x:482, y:425, labelX:-1, labelY:12}),
		war: new City({name: "Warsaw", x:494, y:299, labelX:-1, labelY:12}),
		bel: new City({name: "Belgrade", x:497, y:517, labelX:-1, labelY:12}),
		kie: new City({name: "Kiev", x:626, y:314, labelX:-1, labelY:12}),
		ist: new City({name: "Istanbul", x:629, y:587, labelX:-1, labelY:12}),
		mos: new City({name: "Moscow", x:670, y:137, labelX:-1, labelY:12}),
	}

	let ROADS = new Set([
	])


	class City extends Konva.Group {
		constructor(options) {
			options.draggable = true
			let city = super(options)
			this.isBonus = (options.isBonus == true)

			let circle = new Konva.Circle({
				radius: CONF.cityRadius,
				fill: CONF.mapColor,
				stroke: CONF.cityColor,
				strokeWidth: this.isBonus ? 4 : 3
			})
			circle.on('click', function() {
				if (STATE.selectedCity == null) {
					STATE.selectedCity = city
					circle.stroke(CONF.selectedCityColor)
					return
				}
				if (STATE.selectedCity != city) {
					let road = new Road(STATE.selectedCity, city)
					ROADS.add(road)
					city.getParent().add(road)
					road.moveToBottom()
				}
				STATE.selectedCity.deselect()
				STATE.selectedCity = null
			})
			this.deselect = function() {
				circle.stroke(CONF.cityColor)
			}
			this.add(circle)

			let label = new Konva.Text({
        text: this.name(),
				x: options.labelX ?? -(CONF.cityRadius * 0.1),
        y: options.labelY ?? (CONF.cityRadius * 1.3),
        fontSize: CONF.cityRadius * 2,
        fontFamily: 'Tahoma',
				fontStyle: this.isBonus ? 'bold' : 'normal',
				fill: '#555',
				fillAfterStrokeEnabled: true,
				stroke: CONF.mapColor,
				letterSpacing: 0.7,
				scaleX: 0.8
			})
			label.on('dblclick dbltap', function () {
				let position = this.absolutePosition()
				if (this.textDecoration() == 'underline') {
					this.textDecoration('')
					this.draggable(false)
					this.moveTo(city)
				} else {
					this.textDecoration('underline')
					this.moveTo(city.getParent())
					this.draggable(true)
				}
				this.absolutePosition(position)
			})
			label.on('dragend', function() {
				let position = this.absolutePosition()
				this.textDecoration('')
				this.draggable(false)
				this.moveTo(city)
				this.absolutePosition(position)
				refreshSource()
			})
			this.add(label)

			this.on('dragend', () => refreshSource())

			this.toSourceStr = function() {
				if (this.isBonus) {
					return `${this.abbr()}: new City({name: "${this.name()}", isBonus:true, x:${this.x()}, y:${this.y()}, labelX:${Math.round(label.x())}, labelY:${Math.round(label.y())}})`
				} else {
					return `${this.abbr()}: new City({name: "${this.name()}", x:${this.x()}, y:${this.y()}, labelX:${Math.round(label.x())}, labelY:${Math.round(label.y())}})`
				}
			}
		}

		otherCities(fn) {
			for (var city of Object.values(CITIES)) {
				if (city != this) {
					fn(city)
				}
			}
		}

		abbr() {
			return this.name().slice(0,3).toLowerCase()
		}
	}

/*
  class City0 {
		constructor(name, isBonus, x, y, labelX = -(CONF.cityRadius * 0.1), labelY = (CONF.cityRadius * 1.3)) {
			this.name = name
			this.isBonus = isBonus
			this.x = x
			this.y = y
			this.labelX = labelX
			this.labelY = labelY
			this.group = new Konva.Group({
				x: this.x,
				y: this.y,
				draggable: true
			})
		}

		addToLayer(layer) {
			let group = this.group
			let dot = new Konva.Circle({
				x: 0,
				y: 0,
				radius: CONF.cityRadius,
				fill: CONF.mapColor,
				stroke: 'gray',
				strokeWidth: this.isBonus ? 4 : 3
			})

			let label = new Konva.Text({
        x: this.labelX,
        y: this.labelY,
        text: this.name,
        fontSize: CONF.cityRadius * 2,
        fontFamily: 'Tahoma',
				fontStyle: this.isBonus ? 'bold' : 'normal',
				fill: '#555',
				fillAfterStrokeEnabled: true,
				stroke: CONF.mapColor,
				letterSpacing: 0.7,
				scaleX: 0.8,
				//shadowForStrokeEnabled: false,
				//shadowOpacity: 1,
				//shadowBlur: 0,
				//shadowColor: '#555',
				//shadowOffsetX: 0.85
      })
			group.city = this
			group.on('dragend', function () {
				this.city.x = this.x()
				this.city.y = this.y()
				console.log(`new City0("${this.city.name}", ${this.city.isBonus}, ${this.x()}, ${this.y()}, ${label.x()}, ${label.y()})`)
				return true
			})

			label.on('dblclick dbltap', function () {
				let position = this.absolutePosition()
				if (this.textDecoration() == 'underline') {
					this.textDecoration('')
					this.draggable(false)
					this.moveTo(group)
				} else {
					this.textDecoration('underline')
					this.moveTo(layer)
					this.draggable(true)
				}
				this.absolutePosition(position)
			})
			label.on('dragend', function() {
				let position = this.absolutePosition()
				this.textDecoration('')
				this.draggable(false)
				this.moveTo(group)
				this.absolutePosition(position)
			})

			group.add(dot)
			group.add(label)
			layer.add(group)
		}

		printCode() {

		}
  }
// */

	class Road extends Konva.Group {
		constructor(city1, city2, options = {}) {
			super(options)
			var dX = options.dX ?? 0
			var dY = options.dY ?? 0
			this.dX = dX
			this.dY = dY
			let controlPoint = new Konva.Circle({
				x: (city1.x() + city2.x()) / 2 + this.dX,
				y: (city1.y() + city2.y()) / 2 + this.dY,
				radius: 4,
				stroke: '#777',
				strokeWidth: 1,
				draggable: true
			})
			//var controlPointMoved = false
			//controlPoint.on('dragend', () => controlPointMoved = true)

			let pathPoints = () => [
				city1.x(), city1.y(),
		    controlPoint.x(), controlPoint.y(),
				city2.x(), city2.y()
			]
			let path = new Konva.Line({
				points: pathPoints(),
				stroke: 'gray',
				strokeWidth: 3,
				hitStrokeWidth: 9,
				tension: 0.5,
				bezier: true
			})
		///*
			let tween = null
			this.doFade = function () {
				if (!tween) {
					tween = new Konva.Tween({
						node: controlPoint,
						duration: 1,
						strokeWidth: 0
					})
				}
				tween.play()
			}
			this.doAppear = function () {
				if (tween) {
					tween.reset()
				}
			}
			path.on('mouseout', () => this.doFade())
					.on('mouseover', () => this.doAppear())

	  // */
			let group = this
			let controlPointMoved = function() {
				group.dX = controlPoint.x() - (city1.x() + city2.x()) / 2
				group.dY = controlPoint.y() - (city1.y() + city2.y()) / 2
				path.points(pathPoints())
				refreshSource()
			}

			let endPointMoved = function() {
				if (group) {
					controlPoint.y((city1.y() + city2.y()) / 2 + group.dY)
					controlPoint.x((city1.x() + city2.x()) / 2 + group.dX)
					path.points(pathPoints())
				}
			}

			controlPoint.on('dragmove', () => controlPointMoved())
			controlPoint.on('dragend', function() {
				controlPointMoved()
			})
			city1.on('dragmove', () => endPointMoved())
			city2.on('dragmove', () => endPointMoved())
			this.add(path)
			this.add(controlPoint)

			this.connectsTo = function(city) {
				return city == this.city1 || city == this.city2
			}

			this.toSourceStr = function() {
				if (group.dX != 0 || group.dY != 0) {
					return `new Road(CITIES.${city1.abbr()}, CITIES.${city2.abbr()}, {dX: ${group.dX}, dY: ${group.dY}})`
				} else {
					return `new Road(CITIES.${city1.abbr()}, CITIES.${city2.abbr()})`
				}
			}
		}
	}

	let officialCities = [
		{"name": "London", "closeOrder": 0, "x":603, "y":768, "labelLocation": "topLeft"},
		{"name": "Amsterdam", "closeOrder": 7, "x":733, "y":764, "labelLocation": "top"},
		{"name": "Brussels", "closeOrder": 8, "x":680, "y":848, "labelLocation": "right"},
		{"name": "Stockholm", "closeOrder": 2, "x":921, "y":578},
		{"name": "Berlin", "x":843, "y":800},
		{"name": "Warsaw", "x":1032, "y":808},
		{"name": "Kiev", "closeOrder": 6, "x":1174, "y":826},
		{"name": "Moscow", "closeOrder": 4, "x":1224, "y":641, "labelLocation": "top"},
		{"name": "Vienna", "x":910, "y":933},
		{"name": "Geneva", "x":715, "y":934, "labelLocation": "bottomLeft"},
		{"name": "Paris", "closeOrder": 3, "x":601, "y":886, "labelLocation": "bottomLeft"},
		{"name": "Monaco", "x":712, "y":1027},
		{"name": "Venice", "x":827, "y":1006},
		{"name": "Rome", "closeOrder": 5, "x":843, "y":1103},
		{"name": "Istanbul", "closeOrder": 1, "x":1179, "y":1100},
		{"name": "Budapest", "x":1012, "y":933},
		{"name": "Belgrade", "x":1030, "y":1030}
	]

	onMount(() => {
		// first we need to create a stage
		var stage = new Konva.Stage({
			container: container,   // id of container <div>
			width: CONF.mapWidth,
			height: CONF.mapHeight
		});

		let bgLayer = new Konva.Layer({listening: false})
		bgLayer.add(new Konva.Rect({
			width: stage.width(),
			height: stage.height(),
			fill: CONF.mapColor,
			listening: false
		}))
		// Todo: add map image here
		stage.add(bgLayer)

		var layer = new Konva.Layer();

		for (var cityInfo of officialCities) {
			let city = new City({name: cityInfo.name, x: cityInfo.x - 535, y: cityInfo.y - 510})
			CITIES[city.abbr()] = city
		}

		for (let road of ROADS) {
			layer.add(road)
			road.doFade()
		}
		for (let city of Object.values(CITIES)) {
			layer.add(city)
		}

		refreshSource()
		//console.log(CITIES.bud)
		/*
		let ber = new City0('Berlin', true, 20, 20)
		let vie = new City0('Vienna', false, 180, 80)
		let par = new City0('Paris', false, 50, 300)

		let controlPoint = new Konva.Circle({
			x: (ber.x + vie.x) / 2,
			y: (ber.y + vie.y) / 2,
			radius: 3,
			stroke: 'black',
			strokeWidth: 0.5,
			draggable: true
		})


		controlPoint.on('dragmove', function() {
			updateRoadCurve(road1, controlPoint.x(), controlPoint.y())
		})

		function updateRoadCurve(road, x, y) {
			let points = road.points()
			points[2] = x
			points[3] = y
			road.points(points)
		}

		let road1 = new Konva.Line({
			points: [ber.x, ber.y, controlPoint.x(), controlPoint.y(), vie.x, vie.y],
			stroke: 'gray',
			strokeWidth: 3,
			tension: 0.5,
			bezier: true
		});
		layer.add(road1)
		layer.add(controlPoint)

		let controlPoint2 = new Konva.Circle({
			x: (ber.x + par.x) / 2,
			y: (ber.y + par.y) / 2,
			radius: 4,
			stroke: 'black',
			strokeWidth: 1,
			hitStrokeWidth: 9,
			draggable: true
		})

		let road2 = new Konva.Shape({
			stroke: 'gray',
			strokeWidth: 3,
			hitStrokeWidth: 9,
			fillEnabled: false,
			sceneFunc: (ctx, shape) => {
          ctx.beginPath();
          ctx.moveTo(ber.group.x(), ber.group.y());
          ctx.quadraticCurveTo(
            controlPoint2.x(),
            controlPoint2.y(),
            par.x,
            par.y
          );
          ctx.fillStrokeShape(shape);
        },
		})
		let showControlPoint = function() {
			tween.reset()
		}
		let fadeControlPoint = function() {
			tween.play()
		}
		controlPoint2.on('mouseover', showControlPoint).on('mouseout', fadeControlPoint)
		road2.on('mouseover', showControlPoint).on('mouseout', fadeControlPoint)
		layer.add(road2)
		layer.add(controlPoint2)
		var tween = new Konva.Tween({
        node: controlPoint2,
        duration: 1,
        strokeWidth: 0
      });
		controlPoint2.strokeWidth(0)

		ber.addToLayer(layer)
		vie.addToLayer(layer)
		par.addToLayer(layer)
*/
		stage.add(layer)
		layer.draw();

	})

	function refreshSource() {
		let str = "let CITIES = ["
		for (let [_k, city] of Object.entries(CITIES)) {
			str += `\n  ${city.toSourceStr()},`
		}
		str += "\n]\n\nlet ROADS = new Set(["
		for (let road of ROADS) {
			str += `\n  ${road.toSourceStr()},`
		}
		str += "\n])\n"
// 		console.log(str)
		codeTextField = str
	}

	var newCityX = 20
	var newCityY = CONF.mapHeight - 40
	function addCity() {
		console.log("adding city", newCityName)
		if (newCityName) {
			let city = new City({name: newCityName, x: newCityX, y: newCityY})
			CITIES[city.abbr()] = city
			layer.add(city)
			newCityX += 80
			if (newCityX + 40 > CONF.mapWidth) {
				newCityX += 60 - CONF.mapWidth
				newCityY -= 10
			}
			newCityName = ''
			refreshSource()
		} else {
			console.warn("No name for new city")
		}
	}

	function removeCity() {

	}
</script>

<div bind:this={container}></div>
<div style='margin:16px 0 8px; display:flex; gap:16px'>
	<button on:click={refreshSource} style='margin-right:16px; display:none'>Refresh</button>
	<form on:submit|preventDefault={addCity} style='display:inline'>
		<input type='text' bind:value={newCityName} placeholder='New City Name'/>
		<button type='submit' disabled='{!newCityName}'>Add</button>
	</form>
	<button on:click='{removeCity}' disabled='{!STATE.selectedCity}'>Remove</button>
</div>
<textarea readonly style='font-family:monospace; width:800px; height:600px' on:click={refreshSource}>{codeTextField}</textarea>
<!-- <span on:click={copySource} style='position:absolute'></span>>&#128203;</span> -->
