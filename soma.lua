
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
prev_trigger_time = 0

-- Neuron parameters
neuron_delay = 20 * 1e-3   -- [s]
intensity = 1
connected_somas = {}
-- Stochastic spiking parameters
sigmoid_k =  13.692087
sigmoid_x0 = 1
-- Leaky model parameters
C = 8               -- [nF]
R = 65              -- [MOhms]
tau = C*R * 1e-3    -- [s]
U_rest = -70        -- [mV]
U_current = -70     -- [mV]
U_threshold = -54   -- [mV]
U_pulse = 6         -- [mV]
-- Set movement to 0 for a static growth cone
movement = 1
growth = true

-- Noise parameters
poisson_noise = Stat.randomInteger(0, 0)
process_noise = 0
noise_mean = 0.02
noise_var = 0.01

trigger = 0

time_diff = 0

-- Data collection variables
samples = 10000
firing_times = {}
voltages = {}

function initializeAgent()

    Agent.changeColor{r=255}
    Agent.joinGroup(ID)

    -- Initialize the soma at the middle of the map
    Move.to{x= ENV_WIDTH/2, y= ENV_HEIGHT/2}
    Moving = false


end


function takeStep()

    absolute_time = absolute_time + STEP_RESOLUTION    -- [s]

    -- Stop growth after a specific time
    if growth and absolute_time>460 then
        growth = false
        Event.emit{speed=0, description="stop_growth", targetGroup=ID}
        say("Neuron " .. ID .. " stopped growing: Timeout")
    end

    if trigger==0 then
        -- Normalize the membrane potential for determining the triggering
        U_norm = (U_current-U_rest) / (U_threshold-U_rest)
        -- Use sigmoid function for determining the spiking probability
        trigger_prob = 1 / (1+math.exp(-sigmoid_k*(U_norm-sigmoid_x0)))
        -- Create a trigger based on a Bernouilli distribution
        trigger = Stat.bernouilliInt(trigger_prob)
        if trigger==1 then
            U_current = U_rest
            trigger_time = absolute_time + neuron_delay
        end
    end

    -- Emit events when trigger event is assessed
    if trigger==1 and absolute_time>trigger_time then
        trigger = 0
        Event.emit{speed=0, description="excited_neuron"}
        Event.emit{speed=0, description="electric_pulse", table={intensity}}
        -- Send firing times data to master agent
        if ID==2 then
            diff = absolute_time-(prev_trigger_time+neuron_delay)
            table.insert(firing_times, math.floor(diff*1000))
            prev_trigger_time = absolute_time
            if #firing_times==samples then
                say("Fired " .. samples .. " times. Sending timing to master")
                Event.emit{speed=0,  description="firing_time", table=firing_times}
            end
        end
        U_current = U_rest
    end

    -- Use capacitor equation for calculating the decay of the voltage.
    -- Ignore voltage potentials closer than 0.1 mV from U_rest
    if U_current > U_rest then
        time_diff = absolute_time - synapse_time
        delta_U = U_current - U_rest
        U_current = U_rest + delta_U*math.exp(-time_diff/tau)
    else
        U_current = U_rest
    end
    -- Increase the voltage of the neuron based on the Gaussian distribution
    if trigger==0 then
        U_noise = Stat.gaussianFloat(noise_mean, noise_var)
        U_current = U_current + U_noise
        synapse_time = absolute_time
    end

    -- Record the neuron voltages to csv file
    if ID==2 then
        table.insert(voltages, U_current)
        if #voltages==samples then
            -- Write firing times data to csv file
            file = io.open(script_path().."/log/voltage.csv", "w")
            file:write("U(t)\n")
            for index=1,samples do
                file:write(math.floor(voltages[index]*1000) .. "\n")
            end
            file:close()
            say("Voltages saved to .csv file")
        end
    end

    -- Create new growth cone on initialization or after current cone is
    -- connected
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
                U_current = U_current + 2*U_pulse
            else
                U_current = U_current + U_pulse
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


function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end


function cleanUp()
end
