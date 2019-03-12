
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
trigger_time = 0

-- Neuron parameters
neuron_delay = 20 * 1e-3   -- [s]
intensity = 1
connected_somas = {}
-- Stochastic spiking parameters
sigmoid_k = 14.5479
sigmoid_x0 = 0.5
-- Leaky model parameters
C = 0.5             -- [nF]
R = 40              -- [MOhms]
tau = C*R * 1e-3    -- [s]
U_rest = -70        -- [mV]
U_current = -70     -- [mV]
U_threshold = -54   -- [mV]
delta_U = 15        -- [mV]
-- Set movement to 0 for a static growth cone
movement = 1
poisson_noise = Stat.randomInteger(0, 0)
process_noise = 0
trigger = 0

time_diff = 0

function initializeAgent()

    Agent.changeColor{r=255}
    Agent.joinGroup(ID)

    -- Initialize the soma at the middle of the map
    Move.to{x= ENV_WIDTH/2, y= ENV_HEIGHT/2}
    Moving = false


end


function takeStep()

    absolute_time = absolute_time + STEP_RESOLUTION    -- [s]

    if trigger==0 then
        -- Normalize the membrane potential for determining the triggering
        U_norm = (U_current-U_rest) / (U_threshold-U_rest)
        -- Use sigmoid function for determining the spiking probability
        trigger_prob = 1 / (1+math.exp(-sigmoid_k*(U_norm-sigmoid_x0)))
        trigger = Stat.bernouilliInt(trigger_prob)
        if trigger==1 then
            U_current = U_rest
            trigger_time = absolute_time + neuron_delay
        end
    end

    if trigger==1 and absolute_time>trigger_time then
        trigger = 0
        Event.emit{speed=0, description="excited_neuron", targetGroup=ID}
        Event.emit{speed=0, description="electric_pulse", table={intensity}}
    end

    if U_current > U_rest*0.99 then
        time_diff = absolute_time - synapse_time
        U_current = U_rest + delta_U*math.exp(-time_diff/tau)
    else
        U_current = U_rest
    end

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

    if eventDescription=="synapse" then
        -- Ignore synapses when the neuron triggering is being processed
        if trigger==0 then
            synapse_time = absolute_time
            process_noise = Stat.poissonFloat(poisson_noise) * 1e-3
            if sourceID==1 then
                U_current = U_current + 2*delta_U
            else
                U_current = U_current + delta_U
            end
        end
    end
    if eventDescription=="cone_init" and sourceID==new_agent then
        Event.emit{speed=0, description="assign_group", targetID=new_agent,
                   table={movement, connected_somas}}
    end
    if eventDescription=="cone_connected" and sourceID==new_agent then
        dest_id = eventTable[1]
        connected_somas[dest_id] = 1
        init = true
    end
end

function cleanUp()
end
