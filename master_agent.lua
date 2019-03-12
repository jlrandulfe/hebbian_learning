
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
-- Possible networks: "neuron_pair, ""delay_detector", "coincidence_detector",
-- "leaky_propagation", "reservoir"
network = "coincidence_detector"
agents = {}
-- For reservoir, choose a value that allows to get n_neurons=5*N+1
n_neurons = 26
connections_table = {}
kinematics_table = {["vx"]={}, ["vy"]={}, ["ax"]={}, ["ay"]={}}
final_connections = {}
desired_connections = {}
leaky_connections = {false, false}
leaky_trigger_neuron_3 = true
-- List with the neurons whose triggering has to be omitted
inhibit_trigger = {}

-- Time variables
T_trigger = {}
absolute_time = 0
neuron_delay = 20 * 1e-3   -- [s]
period = 1000 * 1e-3       -- [s]


function initializeAgent()
    say("Master Agent#: " .. ID .. " has been initialized")
    PositionX = -1
    PositionY = -1


    if network=="neuron_pair" then
        n_neurons = 2
        agents[1] = Agent.addAgent("soma.lua", ENV_WIDTH*0.6, ENV_HEIGHT*0.4)
        T_trigger[1] = absolute_time
        inhibit_trigger[1] = 1
        final_connections[agents[1]] = {}
        agents[2] = Agent.addAgent("soma.lua", ENV_WIDTH*0.4, ENV_HEIGHT*0.6)
        T_trigger[2] = absolute_time
        inhibit_trigger[2] = 1
        final_connections[agents[2]] = {}

    elseif network=="coincidence_detector" then
        n_neurons = 3
        -- Create a 3 neurons layout, and get their IDs in a list
        agents[1] = Agent.addAgent("soma.lua", ENV_WIDTH*0.6, ENV_HEIGHT*0.4)
        T_trigger[1] = absolute_time
        final_connections[agents[1]] = {}
        agents[2] = Agent.addAgent("soma.lua", ENV_WIDTH*0.55, ENV_HEIGHT*0.6)
        T_trigger[2] = absolute_time
        final_connections[agents[2]] = {}
        agents[3] = Agent.addAgent("soma.lua", ENV_WIDTH*0.8, ENV_HEIGHT*0.5)
        T_trigger[3] = absolute_time + neuron_delay
        final_connections[agents[3]] = {}

    elseif network=="delay_detector" then
        -- Create N neurons, and get their IDs in a list
        for i=1, n_neurons do
            circular_layout(i, ENV_WIDTH/3, n_neurons)
            -- Set the inital trigger times for the different neurons
            T_trigger[i] = absolute_time +  i * neuron_delay
        end

    elseif network=="leaky_propagation" then
        inhibit_trigger[4]=1
        n_neurons = 4
        -- Create a 4 neurons layout, and get their IDs in a list
        agents[1] = Agent.addAgent("soma.lua", ENV_WIDTH*0.6, ENV_HEIGHT*0.4)
        T_trigger[1] = absolute_time
        final_connections[agents[1]] = {}
        agents[2] = Agent.addAgent("soma.lua", ENV_WIDTH*0.55, ENV_HEIGHT*0.6)
        T_trigger[2] = absolute_time
        final_connections[agents[2]] = {}
        agents[3] = Agent.addAgent("soma.lua", ENV_WIDTH*0.7, ENV_HEIGHT*0.5)
        T_trigger[3] = absolute_time + neuron_delay
        final_connections[agents[3]] = {}
        agents[4] = Agent.addAgent("soma.lua", ENV_WIDTH*0.9, ENV_HEIGHT*0.5)
        T_trigger[4] = absolute_time + 2*neuron_delay
        final_connections[agents[4]] = {}

    elseif network=="reservoir" then
        n_neurons = n_neurons-1
        max_x = 0
        -- Neurons arranged in 4 concentric circles with different radii
        for i=1, n_neurons do
            if i>0 and i<=2*n_neurons/5 then
                r = ENV_WIDTH/3
            elseif i>2*n_neurons/5 and i<=3*n_neurons/5 then
                r = ENV_WIDTH/4
            elseif i>3*n_neurons/5 and i<=4*n_neurons/5 then
                r = ENV_WIDTH/6
            else
                r = ENV_WIDTH/9
            end
            -- Check which is the rightmost neuron, as it will be the
            -- reservoir output.
            ag_x, ag_y = circular_layout(i, r, n_neurons/3, 2*math.pi)
            if ag_x > max_x then
                max_x = ag_x
                output_agent = i
            end
            inhibit_trigger[i] = 1
            T_trigger[i] = absolute_time
        end
        -- Last neuron at the centre of the network
        n_neurons = n_neurons+1
        agents[n_neurons] = Agent.addAgent("soma.lua", ENV_WIDTH/2,
                                           ENV_HEIGHT/2)
        inhibit_trigger[n_neurons] = 1
        T_trigger[n_neurons] = absolute_time
        -- Set 2 neurons as inputs
        inhibit_trigger[7] = -1
        T_trigger[7] = absolute_time
        inhibit_trigger[9] = -1
        T_trigger[9] = absolute_time
        -- Revert trigger parameters of output neuron
        inhibit_trigger[output_agent] = -1
        T_trigger[output_agent] = absolute_time + neuron_delay

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
    absolute_time = absolute_time + STEP_RESOLUTION       -- [s]
    for i=1, n_neurons do
        -- Check if the neuron is in the inhibit list
        if absolute_time > T_trigger[i] then
            if inhibit_trigger[i]~=1 then
                Event.emit{speed=0, description="synapse",
                           targetID=agents[i]}
            end
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
        say(parent_id .." connected to " .. dest_id)
        table.insert(final_connections[parent_id], dest_id)
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
            inhibit_trigger[3] = 1
            inhibit_trigger[4] = -1
        end
    end

end


function linear_layout(index)
    agent_x = index*ENV_WIDTH / (n_neurons+2)
    agent_y = ENV_HEIGHT / 2
    agents[index] = Agent.addAgent("soma.lua", agent_x, agent_y)
end

function circular_layout(index, radius, n, max_angle)
    max_angle = max_angle or 3*math.pi/2
    angle = (max_angle/n) * (index-1)
    agent_x = ENV_WIDTH/2 + radius*math.sin(angle)
    agent_y = ENV_HEIGHT/2 + radius*math.cos(angle)
    agents[index] = Agent.addAgent("soma.lua", agent_x, agent_y)
    final_connections[agents[index]] = {}
    -- Tables with the goal and current neuron connections
    if index>1 then
        desired_connections[agents[index]] = agents[index-1]
    else
        desired_connections[agents[index]] = 0
    end
    return agent_x, agent_y
end


function cleanUp()

    -- Get the success rate and save it to file
    file = io.open(script_path().."/log/success.csv", "w")
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

    -- Get the neurons connections and save it to file
    file = io.open(script_path().."/log/connections.csv", "w")
    file:write("Origin soma;Destination somas\n")
    for index, destinations in pairs(final_connections) do
        file:write(index)
        for dest_index, value in pairs(destinations) do
            if dest_index==1 then
                file:write(";" .. value)
            else
                file:write("," .. value)
            end
        end
        file:write("\n")
    end
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
