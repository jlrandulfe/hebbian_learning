
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

-- Agent properties
move = false

-- Neuron properties
axon_link_length = 5
connected = false
excited = false
excitation_level = 0
min_time_diff = 0.0
max_time_diff = 0.1

absolute_time = 0
excited_neuron_time = 0
received_pulse_time = 0

function initializeAgent()

    Agent.changeColor{g=255}
    -- Initialize the soma at the middle of the map
    say("Axon Agent#: " .. ID .. " has been initialized")
    
    
	Speed = 100
	GridMove = true

    -- Coordinates tracker, for creating new axon agents
    coords = {x1=PositionX, y1=PositionY, x2=PositionX, y2=PositionY}
    -- Table containing info about the coordinates and intensity of incomming
    -- electric pulses.
    pulses_table = {}
end


function takeStep()

    -- Get the distance from the last location where an axon agent was created.
    coords.x1 = PositionX
    coords.y1 = PositionY
    local distance = Math.calcDistance(coords)
    
    -- When the growth cone has travelled enough distance, a new axon segment
    -- agent is created.
	if distance > axon_link_length then
        new_agent = Agent.addAgent("axon.lua", coords.x2, coords.y2)
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
    else
        vx = 0
        vy = 0
    end
    Move.setVelocity{x=vx, y=vy}

    excitation_level = 100000
end


function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)

    if eventDescription == "electric_pulse" then
        -- Get the time difference between the neuron excitation and the
        -- received pulse. Store the electric pulse source if the
        -- difference is between the thresholds.
        received_pulse_time = absolute_time
        time_diff = received_pulse_time - excited_neuron_time
        if time_diff > min_time_diff and time_diff < max_time_diff then
            local intensity = eventTable[1]
            pulses_table[sourceID] = {sourceX, sourceY, intensity}
        end

    elseif eventDescription == "assign_group" then
        Agent.joinGroup(sourceID)

    elseif eventDescription == "excited_neuron" then
        excited = true
        excited_neuron_time = absolute_time
    end

end


function cleanUp()
	say("Agent #: " .. ID .. " is done\n")
end
