love.graphics.setDefaultFilter("nearest", "nearest") -- TEMP, lower

-- The project is not a library, so... globals >:P

consts  = require("consts")

vec2    = require("lib.types.vec2")
vec3    = require("lib.types.vec3")
quat    = require("lib.types.quat")
mat4    = require("lib.types.mat4")

detmath = require("lib.detmath")
list    = require("lib.list")
concord = require("lib.concord")

entity     = concord.entity
component  = concord.component
system     = concord.system
world      = concord.world
assemblage = concord.assemblage

components  = concord.components
systems     = {}
assemblages = {}

concord.utils.loadNamespace("components")
concord.utils.loadNamespace("systems", systems)
concord.utils.loadNamespace("assemblages", assemblages)

local settings = require("settings")
-- local assets = require("assets")
local noice = require("lib.noice")

local ffi = require("ffi")
local uint64 = ffi.typeof("uint64_t")

local world, paused

local loadScene = require("util.loadScene")

function love.load(arg)
	love.graphics.setFrontFaceWinding("cw")
	love.graphics.setDepthMode("lequal", true)
	love.graphics.setMeshCullMode("back")
	
	world = concord.world()
	world.entitiesToAdd = {}
	
	world.chunkWidth, world.chunkHeight, world.chunkDepth = 6, 6, 6
	world.simplexer = noice.newNoiser("OpenSimplex")
	
	world
		:addSystem(systems.quantities)
		:addSystem(systems.drag)
		:addSystem(systems.gravity)
		:addSystem(systems.ais)
		:addSystem(systems.input)
		:addSystem(systems.thrust)
		:addSystem(systems.shooting)
		:addSystem(systems.movement)
		:addSystem(systems.physics)
		:addSystem(systems.rendering)
		:addSystem(systems.HUD)
	
	loadScene("testworld", world:getSystem(systems.rendering), world:getSystem(systems.physics))
	
	local player = entity():assemble(assemblages.testman, 0, 0, 0):give("player"):give("camera"):give("emission", 100, 100, 100):give("gravitationalAcceleration")
	local otherGuy = entity():assemble(assemblages.testman, 2, 2, -10)
	
	-- local gravity = entity():give("gravity", 0, 0, -10)
	-- local air = entity():give("air", 0.5)
	-- local platform = entity():give("orientation"):give("drawable", "floar"):give("position", 0, 0, -3)
	
	world
		:addEntity(player)
		:addEntity(otherGuy)
		-- :addEntity(gravity)
		-- :addEntity(air)
		-- :addEntity(platform)
	
	paused = false
end

function love.draw(lerp, deltaDrawTime)
	world:emit("draw", lerp, deltaDrawTime)
	love.graphics.push()
	
	-- OpenGL --> LÖVE
	love.graphics.scale(1, -1)
	love.graphics.translate(0, -love.graphics.getHeight())
	
	love.graphics.draw(world:getSystem(systems.rendering).output)
	love.graphics.draw(world:getSystem(systems.HUD).output)
	love.graphics.pop()
end

function love.update(dt)
	
end

function love.detupdate(dt)
	-- assert(dt == consts.tickLength)
	for _, entity in ipairs(world.entitiesToAdd) do
		world:addEntity(entity)
	end
	world.entitiesToAdd = {}
	world:emit("update", dt)
end

function love.quit()
	
end

function love.run()
	love.load(love.arg.parseGameArguments(arg))
	local lag = consts.tickLength
	local updatesSinceLastDraw, lastLerp = 0, 1
	love.timer.step()
	
	return function()
		love.event.pump()
		for name, a,b,c,d,e,f in love.event.poll() do -- Events
			if name == "quit" then
				if not love.quit() then
					return a or 0
				end
			end
			love.handlers[name](a,b,c,d,e,f)
		end
		
		do -- Update
			local delta = love.timer.step()
			lag = math.min(lag + delta, consts.tickLength * consts.maxTicksPerFrame)
			local frames = math.floor(lag / consts.tickLength)
			lag = lag % consts.tickLength
			love.update(dt)
			if not paused then
				local start = love.timer.getTime()
				for _=1, frames do
					updatesSinceLastDraw = updatesSinceLastDraw + 1
					love.detupdate(consts.tickLength)
				end
			end
		end
		
		if love.graphics.isActive() then -- Rendering
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())
			
			local lerp = lag / consts.tickLength
			deltaDrawTime = ((lerp + updatesSinceLastDraw) - lastLerp) * consts.tickLength
			love.draw(lerp, deltaDrawTime)
			updatesSinceLastDraw, lastLerp = 0, lerp
			
			love.graphics.present()
		end
		
		love.timer.sleep(0.001)
	end
end
