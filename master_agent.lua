
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
-- Possible networks: "delay_detector", "coincidence_detector",
-- "leaky_propagation"
network = "leaky_propagation"
agents = {}
n_neurons = 8
connections_table = {}
kinematics_table = {["vx"]={}, ["vy"]={}, ["ax"]={}, ["ay"]={}}
final_connections = {}
desired_connections = {}
leaky_connections = {false, false}
leaky_trigger_neuron_3 = true

-- Time variables
T_trigger = {}
Tn = 0
neuron_delay = 20 * 1e-3   -- [s]
period = 1000 * 1e-3       -- [s]


function initializeAgent()
    say("Master Agent#: " .. ID .. " has been initialized")
    PositionX = -1
    PositionY = -1

    if network=="coincidence_detector" then
        n_neurons = 3
        -- Create a 3 neurons layout, and get their IDs in a list
        agents[1] = Agent.addAgent("soma.lua", ENV_WIDTH*0.6, ENV_HEIGHT*0.4)
        T_trigger[1] = Tn
        agents[2] = Agent.addAgent("soma.lua", ENV_WIDTH*0.4, ENV_HEIGHT*0.6)
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

    elseif network=="leaky_propagation" then
        n_neurons = 3
        -- Create a 4 neurons layout, and get their IDs in a list
        agents[1] = Agent.addAgent("soma.lua", ENV_WIDTH*0.6, ENV_HEIGHT*0.4)
        T_trigger[1] = Tn
        agents[2] = Agent.addAgent("soma.lua", ENV_WIDTH*0.5, ENV_HEIGHT*0.6)
        T_trigger[2] = Tn
        agents[3] = Agent.addAgent("soma.lua", ENV_WIDTH*0.7, ENV_HEIGHT*0.5)
        T_trigger[3] = Tn + neuron_delay
        agents[4] = Agent.addAgent("soma.lua", ENV_WIDTH*0.9, ENV_HEIGHT*0.5)
        T_trigger[4] = Tn + 4*neuron_delay

    else
        say("Invalid network: " .. network)
    end

    -- pulse_agent = Agent.addAgent("pulse_generator.lua", ENV_WIDTH-10,
    --                              ENV_HEIGHT-10)

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
        -- Do not trigger the 3rd neuron in the Leaky network
        -- after condition is met
        if Tn > T_trigger[i] then
            Event.emit{speed=0, description="synapse",
                       targetID=agents[i]}
            T_trigger[i] = T_trigger[i] + period
        end
    end
end


function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)

    if eventDescription == "cone_parent" then
        cone_id = eventTable["cone_id"]
        parent_id = eventTable["parent_id"]
        connections_table[cone_id] = parent_id
    end

    if eventDescription == "cone_kinematics" then
        kinematics_table = eventTable
    end

    if eventDescription == "cone_connected" then
        dest_id = eventTable[1]
        parent_id = eventTable[2]
        final_connections[parent_id] = dest_id
        -- Check connection of intermediate neuron for Leaky network
        if network=="leaky_propagation" and  parent_id==4 then
            if dest_id==2 then
                leaky_connections[1] = true
            elseif dest_id==3 then
                leaky_connections[2] = true
            end
        end
        if leaky_connections[1] and leaky_connections[2] then
            say("Sending pulses to neuron ID 5")
            n_neurons = 4
            leaky_trigger_neuron_3 = false
        end
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
    -- Tables with the goal and current neuron connections
    if index>1 then
        desired_connections[agents[index]] = agents[index-1]
    else
        desired_connections[agents[index]] = 0
    end
    final_connections[agents[index]] = 0
end


function cleanUp()
    -- Get the success rate and save it to file
    file = io.open(script_path().."/log/connections.csv", "w")
    file:write("Origin soma;Destination soma;Success\n")
    final_success = 0
    for index, value in pairs(desired_connections) do
        if final_connections[index] == value then
            success = 1
        else
            success = 0
        end
        final_success = final_success + success
        file:write(index..";"..value..";"..success.."\n")
    end
    if #desired_connections > 0 then
        success_rate = final_success / #desired_connections
    else
        success_rate = -1
    end
    file:write(";Suc. rate;"..success_rate.."\n")
    file:close()

    -- Write kinematics data to csv file
    file = io.open(script_path().."/log/kinematics.csv", "w")
    file:write("v_x,v_y,a_x,a_y\n")
    v_x = kinematics_table["vx"]
    v_y = kinematics_table["vy"]
    a_x = kinematics_table["ax"]
    a_y = kinematics_table["ay"]
    for index=1,#v_x do
        file:write(v_x[index] .. "," .. v_y[index] .. "," .. a_x[index]
                   .. "," .. a_y[index] .. "\n")
    end
    file:close()
end
