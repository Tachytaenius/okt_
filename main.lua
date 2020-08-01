love.graphics.setDefaultFilter("nearest", "nearest") -- TEMP, lower

-- The project is not a library, so... globals >:P

consts  = require("consts")

vec2    = require("types.vec2")
vec3    = require("types.vec3")
quat    = require("types.quat")
mat4    = require("types.mat4")

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
-- local assets   = require("assets")

local world, paused

function love.load(arg)
	love.graphics.setDepthMode("lequal", true)
	love.graphics.setMeshCullMode("front") -- TEMP. Vertex winding issues.
	
	world = concord.world():
		addSystem(systems.quantities):
		addSystem(systems.ais):
		addSystem(systems.input):
		addSystem(systems.thrust):
		addSystem(systems.movement):
		addSystem(systems.rendering):
		addEntity(entity():assemble(assemblages.testman)):
		addEntity(entity():assemble(assemblages.testman):give("player"):give("camera")):
		addEntity(entity():give("emission", 1, 1, 1):give("position", 0, 0, 0))
	world.entitiesToAdd = {}
	world.gravity = vec3(0, 0, 0)
	paused = false
end

function love.draw(lerp)
	world:emit("draw", lerp)
	love.graphics.push()
	love.graphics.scale(1, -1) -- OpenGL --> LÖVE
	love.graphics.translate(0, -love.graphics.getHeight())
	love.graphics.setShader(love.graphics.newShader([[
		vec4 effect(vec4 colour, sampler2D image, vec2 tc, vec2 wc) {
			return vec4(Texel(image, tc).rgb, 1.0);
		}
	]]))
	love.graphics.draw(world:getSystem(systems.rendering).lighting)
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
					love.detupdate(consts.tickLength)
				end
			end
		end
		
		if love.graphics.isActive() then -- Rendering
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())
			love.draw(lag / consts.tickLength)
			love.graphics.present()
		end
		
		love.timer.sleep(0.001)
	end
end
