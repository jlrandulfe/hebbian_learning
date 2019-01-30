
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

-- Agents parameters
n_neurons = 2
agents = {}

-- Time variables
T_trigger = {}
Tn = 0
neuron_delay = 100 * 1e-3   -- [s]
period = 1000 * 1e-3        -- [s]

function initializeAgent()
    say("Master Agent#: " .. ID .. " has been initialized")
    PositionX = -1
    PositionY = -1

    -- Create N neurons, and get their IDs in a list
    for i=1, n_neurons do
        agents[i] = Agent.addAgent("soma.lua", i * ENV_WIDTH / (n_neurons+2),
                                       ENV_HEIGHT/2)
        -- Set the inital trigger times for the different neurons
        T_trigger[i] = Tn +  i * neuron_delay
    end

end


function takeStep()

    -- Keep track of time, and send excitations to each neuron depending on
    -- their corresponding delays.
    Tn = Tn + STEP_RESOLUTION       -- [s]
    for i=1, n_neurons do
        if Tn > T_trigger[i] then
            Event.emit{speed=0, description="synapse",
                       targetID=agents[i]}
            T_trigger[i] = T_trigger[i] + period
        end
    end
end


function cleanUp()
	say("Agent #: " .. ID .. " is done\n")
end
