
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
Move = require "ranalib_movement"
Math = require "ranalib_math"


-- Environment properties
env_noise_mean = 10

-- Agent properties
move = false
parent_soma_id = -1
init = true
initial_axon_link = true

-- Neuron properties
axon_link_length = 2
connected = false
excited = false
excitation_level = 0

-- Hebbian learning parameters
amp = 1
negative_amp = 0.6
min_time_diff = 0.0
max_time_diff = 0.12
tau = 0.02

absolute_time = 0
excited_neuron_time = 0
received_pulse_time = 0

function initializeAgent()

    Agent.changeColor{g=255}
    -- Initialize the soma at the middle of the map
    -- say("Growth cone Agent#: " .. ID .. " has been initialized")

	Speed = 100
	GridMove = true

    -- Coordinates tracker, for creating new axon agents
    coords = {x1=PositionX, y1=PositionY, x2=PositionX, y2=PositionY}
    -- Tables containing info about the coordinates and towards incomming
    -- electric pulses, and the raw data of such pulses.
    pulses_table = {}
    received_pulses = {}
end


function takeStep()

    if init == true then
        Event.emit{speed=0, description="cone_init"}
    end

    -- Get the distance from the last location where an axon agent was created.
    coords.x1 = PositionX
    coords.y1 = PositionY
    local distance = Math.calcDistance(coords)
    
    -- When the growth cone has travelled enough distance, a new axon segment
    -- agent is created.
    if distance > axon_link_length then
        if not initial_axon_link then
            new_agent = Agent.addAgent("spine.lua", coords.x2, coords.y2)
        else
            initial_axon_link = false
        end
        coords.x2 = PositionX
        coords.y2 = PositionY
	end

    if excitation_level > 80 then
        Moving = true
    else
        Moving = false
    end

    -- Decrease the excitation level with time
    if excitation_level > 0 then
        excitation_level = excitation_level - 1
    elseif excitation_level < 0 then
        excitation_level = excitation_level + 1
    end

    absolute_time = absolute_time + STEP_RESOLUTION

    -- Set the growth cone direction to the electric pulse source
    local vx = 0
    local vy = 0
    if not connected then
        for key, values in pairs(pulses_table) do
            -- Calculate the absolute distance and its X, Y decomposition
            dx = values[1] - PositionX
            dy = values[2] - PositionY
            distance = math.sqrt(math.pow(dx, 2)+math.pow(dy, 2))
            if distance < 2 then
                say("Connected\n")
                connected = true
            end
            -- Calculate the unit vector pointing towards the source
            orientationX = dx / distance
            orientationY = dy / distance
            -- Get the velocity vector
            vx = vx + orientationX*values[3]
            vy = vy + orientationY*values[3]
        end
        -- Environment noise.
        local env_noise_angle = Stat.randomFloat(0, 2*math.pi)
        local env_noise_amp = Stat.gaussianFloat(0, env_noise_mean)
        vx = vx + (env_noise_amp * math.cos(env_noise_angle))
        vy = vy + (env_noise_amp * math.sin(env_noise_angle))

    else
        vx = 0
        vy = 0
    end
    Move.setVelocity{x=vx, y=vy}

    excitation_level = 100000
end


function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)

    if eventDescription == "electric_pulse" then
        -- Ignore the pulse if parent-child relationship is not initialized,
        -- nor if the received pulse is from parent
        if sourceID == parent_soma_id or parent_soma_id == -1 then
            valid_source = false
        else
            valid_source = true
        end
        -- Get the time difference between the neuron excitation and the
        -- received pulse. Store the electric pulse source if the
        -- difference is between the thresholds.
        received_pulse_time = absolute_time
        time_diff = received_pulse_time - excited_neuron_time
        if time_diff > min_time_diff and time_diff < max_time_diff then
            valid_time = true
        else
            valid_time = false
        end
        if valid_source then
            local intensity = eventTable[1]
            if valid_time then
                -- Hebbian learning negative side
            end
            received_pulses[sourceID] = {sourceX, sourceY, intensity,
                                         received_pulse_time}
        end

    elseif eventDescription == "assign_group" then
        init = false
        parent_soma_id = sourceID
        movement = eventTable[1]
        -- If a 0 is received, the growth cone is static and does not grow
        if movement == 0 then
            connected = true
        end
        Event.emit{speed=0,description="cone_connection",
                   table={["cone_id"]=ID, ["parent_id"]=sourceID}}

    elseif eventDescription == "excited_neuron" then
        if sourceID == parent_soma_id then
            excited = true
            excited_neuron_time = absolute_time
            for key, values in pairs(received_pulses) do
                pulse_time = values[4]
                local intensity = values[3]
                time_diff = excited_neuron_time - pulse_time
                if time_diff < max_time_diff then
                    -- Hebbian rule positive side
                    intensity = intensity * amp * math.exp(
                            -math.abs(time_diff)/tau)
                else
                    intensity = intensity * 0.01
                end
                pulses_table[key] = {values[1], values[2], intensity,
                                     values[4]}
            end
        end
    end

end


function cleanUp()
end
