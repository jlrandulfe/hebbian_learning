
--The following global values are set via the simulation core:
-- ------------------------------------
-- IMMUTABLES.
-- ------------------------------------
-- ID               -- id of the agent.
-- STEP_RESOLUTION 	-- resolution of steps, in the simulation core.
-- EVENT_RESOLUTION	-- resolution of event distribution.
-- ENV_WIDTH        -- Width of the environment in meters.
-- ENV_HEIGHT       -- Height of the environment in meters.
-- ------------------------------------
-- VARIABLES.
-- ------------------------------------
-- PositionX	 	-- Agents position in the X plane.
-- PositionY	 	-- Agents position in the Y plane.
-- DestinationX 	-- Agents destination in the X plane. 
-- DestinationY 	-- Agents destination in the Y plane.
-- StepMultiple 	-- Amount of steps to skip.
-- Speed 			-- Movement speed of the agent in meters pr. second.
-- Moving 			-- Denotes wether this agent is moving (default = false).
-- GridMove 		-- Is collision detection active (default = false).
-- ------------------------------------

Agent = require "ranalib_agent"
Stat = require "ranalib_statistic"
Event = require "ranalib_event"

n_neurons = 1

function initializeAgent()
    say("Master Agent#: " .. ID .. " has been initialized")
    PositionX = -1
    PositionY = -1

    -- Add neurons
    for i=1, n_neurons do
        Agent.addAgent("soma.lua", 60, ENV_HEIGHT/2)	
    end

    pulse_generator1 = Agent.addAgent("pulse_generator.lua", ENV_WIDTH-10, 10)
    pulse_generator2 = Agent.addAgent("pulse_generator.lua", ENV_WIDTH-10,
                                      ENV_HEIGHT-10)	
end


function takeStep()
    Event.emit{speed=0, description="set_intensity", targetID=pulse_generator1,
               table={["intensity"]=150}}
    Event.emit{speed=0, description="set_intensity", targetID=pulse_generator2,
               table={["intensity"]=90}}
	Agent.removeAgent(ID)
end


function cleanUp()
	say("Agent #: " .. ID .. " is done\n")
end
