
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

Event = require "ranalib_event"
Agent = require "ranalib_agent"

local intensity = 0

function initializeAgent()

    say("Pulse generator #: " .. ID .. " has been initialized")
    Agent.changeColor{r=255, g=255, b=255}

end


function takeStep()

    -- Event for sending an electric pulse to the neurons
    Event.emit{speed=0, description="electric_pulse", table={intensity}}
    
end


function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)

    if eventDescription == "set_intensity" then
        intensity = eventTable["intensity"]
    end

end


function cleanUp()
	say("Agent #: " .. ID .. " is done\n")
end
