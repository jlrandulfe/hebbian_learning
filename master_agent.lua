
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

-- Network parameters
network = "delay_detector"
agents = {}
n_neurons = 8
connections_table = {}

-- Time variables
T_trigger = {}
Tn = 0
neuron_delay = 20 * 1e-3   -- [s]
period = 1000 * 1e-3        -- [s]


function initializeAgent()
    say("Master Agent#: " .. ID .. " has been initialized")
    PositionX = -1
    PositionY = -1

    if network=="coincidence_detector" then
        n_neurons = 3
        -- Create a 3 neurons layout, and get their IDs in a list
        agents[1] = Agent.addAgent("soma.lua", ENV_WIDTH*0.1, ENV_HEIGHT*0.4)
        T_trigger[1] = Tn
        agents[2] = Agent.addAgent("soma.lua", ENV_WIDTH*0.1, ENV_HEIGHT*0.6)
        T_trigger[2] = Tn
        agents[3] = Agent.addAgent("soma.lua", ENV_WIDTH*0.8, ENV_HEIGHT*0.5)
        T_trigger[3] = Tn + neuron_delay

    elseif network=="delay_detector" then
        -- Create N neurons, and get their IDs in a list
        for i=1, n_neurons do
            circular_layout(i, ENV_WIDTH/3)
            -- Set the inital trigger times for the different neurons
            T_trigger[i] = Tn +  i * neuron_delay
        end

    else
        say("Invalid network: " .. network)
    end

    pulse_agent = Agent.addAgent("pulse_generator.lua", ENV_WIDTH-10,
                                 ENV_HEIGHT-10)

end


function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
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


function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)

    if eventDescription == "cone_connection" then
        cone_id = eventTable["cone_id"]
        parent_id = eventTable["parent_id"]
        connections_table[cone_id] = parent_id
    end

end


function linear_layout(index)
    agent_x = index*ENV_WIDTH / (n_neurons+2)
    agent_y = ENV_HEIGHT / 2
    agents[index] = Agent.addAgent("soma.lua", agent_x, agent_y)
end

function circular_layout(index, radius)
    max_angle = 3*math.pi / 2
    angle = (max_angle/n_neurons) * (index-1)
    agent_x = ENV_WIDTH/2 + radius*math.sin(angle)
    agent_y = ENV_HEIGHT/2 + radius*math.cos(angle)
    agents[index] = Agent.addAgent("soma.lua", agent_x, agent_y)
end


function cleanUp()
    -- Open output file
    file = io.open(script_path().."/log/connections"..ID..".csv", "w")

    -- Write some information to the file
    file:write("Cone ID,Parent ID\n")
    for index, value in pairs(connections_table) do
        file:write(index..","..value.."\n")
    end

    file:close()
end
