
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
agents = {}
n_neurons = 3

-- Time variables
T_trigger = {}
Tn = 0
neuron_delay = 20 * 1e-3   -- [s]
period = 1000 * 1e-3        -- [s]


function initializeAgent()
    say("Master Agent#: " .. ID .. " has been initialized")
    PositionX = -1
    PositionY = -1

    -- Create a 3 neurons layout, and get their IDs in a list
    agents[1] = Agent.addAgent("soma.lua", ENV_WIDTH*0.1, ENV_HEIGHT*0.4)
    T_trigger[1] = Tn
    agents[2] = Agent.addAgent("soma.lua", ENV_WIDTH*0.1, ENV_HEIGHT*0.6)
    T_trigger[2] = Tn
    agents[3] = Agent.addAgent("soma.lua", ENV_WIDTH*0.8, ENV_HEIGHT*0.5)
    T_trigger[3] = Tn + neuron_delay

    pulse_agent = Agent.addAgent("pulse_generator.lua", ENV_WIDTH-10,
                                 ENV_HEIGHT-10)
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
end
