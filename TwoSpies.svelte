<script>
	import Konva from 'konva@8/lib/Core'
  import { Circle } from "konva/lib/shapes/Circle";
 	import { Text } from "konva/lib/shapes/Text";
 	import { Rect } from "konva/lib/shapes/Rect";
	import { Line } from "konva/lib/shapes/Line";
	import { Image } from "konva/lib/shapes/Image";

	import {onMount} from 'svelte'

	// Svelte bindings
	let container
	let newCityName
	var codeTextField = ''

	const CONF = {
		cityRadius: 9,
		mapColor: '#f7f4e9',
		seaColor: '#9FCDBA',
		mapWidth: 800,
		mapHeight: 700,
		cityColor: 'gray',
		selectedCityColor: 'black',
	}

	let STATE = {
		selectedCity: null
	}

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
					let existingRoad = null
					for (let other of ROADS) {
						if (other.connectsTo(city) && other.connectsTo(STATE.selectedCity)) {
							existingRoad = other
						}
					}
					if (existingRoad) {
						removeRoad(existingRoad)
					} else {
						ROADS.add(road)
						city.getParent().add(road)
						road.moveToBottom()
						road.doFade()
					}
					refreshSource()
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

			let tween = null
			this.doFade = function () {
		///*  // comment out to always show control points
				if (!tween) {
					tween = new Konva.Tween({
						node: controlPoint,
						duration: 1,
						strokeWidth: 0
					})
				}
				tween.play()
	  // */
			}
			this.doAppear = function () {
				if (tween) {
					tween.reset()
				}
			}
			path.on('mouseout', () => this.doFade())
					.on('mouseover', () => this.doAppear())

			let group = this
			let controlPointMoved = function() {
				group.dX = controlPoint.x() - (city1.x() + city2.x()) / 2
				group.dY = controlPoint.y() - (city1.y() + city2.y()) / 2
				path.points(pathPoints())
				refreshSource()
			}

			let endPointMoved = function() {
				if (group) {
					controlPoint.x((city1.x() + city2.x()) / 2 + group.dX)
					controlPoint.y((city1.y() + city2.y()) / 2 + group.dY)
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
				//console.log(city, this.city1)
				return city == city1 || city == city2
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

	// Replace this section to save the map:

let CITIES = {
  par: new City({name: "Paris", x:251, y:425, labelX:-45, labelY:2}),
  lon: new City({name: "London", x:233, y:362, labelX:-44, labelY:-30}),
  bru: new City({name: "Brussels", x:288, y:400, labelX:14, labelY:-9}),
  mon: new City({name: "Monaco", x:317, y:520, labelX:-20, labelY:9}),
  gen: new City({name: "Geneva", x:306, y:461, labelX:-43, labelY:7}),
  ams: new City({name: "Amsterdam", x:323, y:356, labelX:-28, labelY:-35}),
  ven: new City({name: "Venice", x:384, y:508, labelX:10, labelY:7}),
  rom: new City({name: "Rome", x:406, y:569, labelX:-1, labelY:12}),
  ber: new City({name: "Berlin", isBonus:true, x:405, y:378, labelX:-1, labelY:12}),
  vie: new City({name: "Vienna", x:454, y:457, labelX:-1, labelY:12}),
  sto: new City({name: "Stockholm", x:456, y:237, labelX:-1, labelY:12}),
  bud: new City({name: "Budapest", x:538, y:458, labelX:13, labelY:-1}),
  war: new City({name: "Warsaw", x:547, y:377, labelX:3, labelY:11}),
  bel: new City({name: "Belgrade", x:547, y:520, labelX:-43, labelY:10}),
  kie: new City({name: "Kiev", x:640, y:390, labelX:-1, labelY:12}),
  ist: new City({name: "Istanbul", x:649, y:574, labelX:-1, labelY:12}),
  mos: new City({name: "Moscow", x:677, y:280, labelX:-1, labelY:12}),
}

let ROADS = new Set([
  new Road(CITIES.lon, CITIES.par),
  new Road(CITIES.lon, CITIES.bru),
  new Road(CITIES.lon, CITIES.ams),
  new Road(CITIES.par, CITIES.bru),
  new Road(CITIES.bru, CITIES.ams),
  new Road(CITIES.par, CITIES.gen),
  new Road(CITIES.gen, CITIES.bru),
  new Road(CITIES.par, CITIES.mon, {dX: -19, dY: 10}),
  new Road(CITIES.gen, CITIES.mon, {dX: 7, dY: 0}),
  new Road(CITIES.gen, CITIES.ven),
  new Road(CITIES.mon, CITIES.ven),
  new Road(CITIES.mon, CITIES.rom),
  new Road(CITIES.ven, CITIES.rom),
  new Road(CITIES.rom, CITIES.ist, {dX: -45, dY: 10}),
  new Road(CITIES.ven, CITIES.vie, {dX: -13, dY: -2}),
  new Road(CITIES.vie, CITIES.ber),
  new Road(CITIES.ber, CITIES.gen),
  new Road(CITIES.ams, CITIES.ber),
  new Road(CITIES.ber, CITIES.sto, {dX: 4, dY: 4}),
  new Road(CITIES.sto, CITIES.ams, {dX: 3, dY: 6}),
  new Road(CITIES.sto, CITIES.mos, {dX: 2, dY: 25}),
  new Road(CITIES.sto, CITIES.war, {dX: -16, dY: -2}),
  new Road(CITIES.ber, CITIES.war),
  new Road(CITIES.vie, CITIES.bud),
  new Road(CITIES.vie, CITIES.war, {dX: 2, dY: 5}),
  new Road(CITIES.war, CITIES.kie),
  new Road(CITIES.war, CITIES.mos, {dX: -17, dY: -4}),
  new Road(CITIES.mos, CITIES.kie, {dX: 1, dY: 7}),
  new Road(CITIES.kie, CITIES.ist, {dX: -24, dY: 41}),
  new Road(CITIES.bud, CITIES.war),
  new Road(CITIES.bud, CITIES.kie, {dX: 3, dY: 14}),
  new Road(CITIES.bud, CITIES.ist, {dX: 0, dY: 15}),
  new Road(CITIES.bel, CITIES.ist, {dX: -5, dY: 9}),
  new Road(CITIES.bel, CITIES.bud, {dX: -6, dY: 2}),
  new Road(CITIES.bel, CITIES.vie, {dX: 8, dY: -2}),
  new Road(CITIES.bel, CITIES.kie, {dX: -10, dY: 30}),
  new Road(CITIES.vie, CITIES.ist, {dX: -25, dY: 26}),
  new Road(CITIES.ven, CITIES.bel, {dX: 12, dY: -6}),
])



	// End of section

	let layer
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
			fill: CONF.seaColor,
			listening: false
		}))
		let mapImg = new window.Image()
		mapImg.src = "https://gist.github.com/dazworks/f250de34784f9e36d3583ba337e2ffe4/raw/8ff0a6079d8b5048e8f106427913e4653ae4f0a6/map.svg"
		let map = new Konva.Image({image: mapImg })
		bgLayer.add(map)
		map.x(-80)
		map.y(-100)
		map.width(stage.width()+200)
		map.height(stage.height()+200)
		stage.add(bgLayer)

		layer = new Konva.Layer();

		for (let road of ROADS) {
			layer.add(road)
			road.doFade()
		}
		for (let city of Object.values(CITIES)) {
			layer.add(city)
		}

		refreshSource()

		stage.add(layer)
		layer.draw();

	})

	function refreshSource() {
		let str = "let CITIES = {"
		for (let [_k, city] of Object.entries(CITIES)) {
			str += `\n  ${city.toSourceStr()},`
		}
		str += "\n}\n\nlet ROADS = new Set(["
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

	function addDisabled() {
		return !newCityNameInput || newCityNameInput.value == ""
	}

	function removeRoad(road) {
		ROADS.delete(road)
		road.destroy()
		refreshSource()
	}

	function removeCity() {
		let city = STATE.selectedCity
		for (let road of ROADS) {
			if (road.connectsTo(city)) {
				removeRoad(road)
			}
		}
		STATE.selectedCity = null
		city.destroy()
		delete CITIES[city.abbr()]
		refreshSource()
	}
</script>

<div bind:this={container}></div>
<div style='margin:16px 0 8px; display:flex; gap:16px'>
	<form on:submit|preventDefault={addCity} style='display:inline'>
		<input type='text' bind:value={newCityName} placeholder='New City Name'/>
		<button type='submit' disabled='{!newCityName}'>Add</button>
	</form>
	<button on:click='{removeCity}' disabled='{!STATE.selectedCity}'>Remove</button>
</div>
<textarea readonly style='font-family:monospace; width:800px; height:600px' on:click={refreshSource}>{codeTextField}</textarea>
<!-- <span on:click={copySource} style='position:absolute'></span>>&#128203;</span> -->
