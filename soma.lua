
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
Move = require "ranalib_movement"
Map = require "ranalib_map"
Event = require "ranalib_event"


init = true

-- Timing variables
absolute_time = 0
synapse_time = 0

-- Neuron parameters
intensity = 1
-- Set movement to 0 for a static growth cone
movement = 1
if true then
    poisson_noise = Stat.randomInteger(0, 1)
else
    poisson_noise = 0
end

-- poisson_noise = Stat.randomInteger(5, 30)
synapse = false
process_noise = 0

function initializeAgent()

    Agent.changeColor{r=255}
    Agent.joinGroup(ID)

    -- Initialize the soma at the middle of the map
    Move.to{x= ENV_WIDTH/2, y= ENV_HEIGHT/2}
    Moving = false

    -- -- Inhibit movement on the 3rd neuron. For the coincidence detector
    -- if ID==4 then
    --     movement = 0
    -- end

end


function takeStep()

    absolute_time = absolute_time + STEP_RESOLUTION

    if (absolute_time > synapse_time+process_noise) and synapse then
        Event.emit{speed=0, description="excited_neuron", targetGroup=ID}
        Event.emit{speed=0, description="electric_pulse", table={intensity}}
        synapse = false
    end

    if init then
        new_agent = Agent.addAgent("growth_cone.lua", PositionX, PositionY)
        init = false
    end

end


function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)

    if eventDescription == "synapse" then
        synapse_time = absolute_time
        process_noise = Stat.poissonFloat(poisson_noise) * 1e-3
        synapse = true
    end
    if eventDescription == "cone_init" and sourceID == new_agent then
        Event.emit{speed=0, description="assign_group", targetID=new_agent,
                   table={movement}}
    end
end

function cleanUp()
end
