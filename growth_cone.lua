
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


-- Experiment variables
analyzed_soma = 4
reg_rate = 100
record_kinematics = false

-- Environment properties
env_noise_var = 0.5
drag_coef = 0.8

-- Agent properties
move = false
parent_id = -1
init = false
initial_spine_link = true
step = 0
-- Multiplying factor for emitting float numbers
conv_factor = 100000

-- Neuron properties
spine_link_length = 2
connected = false
excited = false
excitation_level = 0
vx = 0
vy = 0
kinematics_table = {["vx"]={}, ["vy"]={}, ["ax"]={}, ["ay"]={}}
nonvalid_somas = {}

-- Hebbian learning parameters
amp = 1
negative_amp = 0.6
min_time_diff = 0.01
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

    -- Coordinates tracker, for creating new spine agents
    coords = {x1=PositionX, y1=PositionY, x2=PositionX, y2=PositionY}
    -- Tables containing info about the coordinates and towards incomming
    -- electric pulses, and the raw data of such pulses.
    pulses_table = {}
    received_pulses = {}
end


function takeStep()
    absolute_time = absolute_time + STEP_RESOLUTION
    step = step + 1

    if not init then
        Event.emit{speed=0, description="cone_init"}
    else
        -- Create a spine agent, if necessary
        create_spine_agent()

        -- Set the growth cone velocity based on the electric pulse sources
        if connected then
            vx = 0
            vy = 0
            ax = 0
            ay = 0
        else
            ax_drag, ay_drag = get_drag_force(vx, vy)
            ax, ay = get_acceleration(ax_drag, ay_drag)
            vx = vx + ax*STEP_RESOLUTION
            vy = vy + ay*STEP_RESOLUTION
        end
        Move.setVelocity{x=vx, y=vy}

        -- Register kinematics data to table for further storage
        if math.fmod(step, reg_rate)==0 and parent_id==analyzed_soma
                and record_kinematics then
            table.insert(kinematics_table["vx"], math.floor(conv_factor*vx+0.5))
            table.insert(kinematics_table["vy"], math.floor(conv_factor*vy+0.5))
            table.insert(kinematics_table["ax"], math.floor(conv_factor*ax+0.5))
            table.insert(kinematics_table["ay"], math.floor(conv_factor*ay+0.5))
        end
    end
end


function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)

    if eventDescription == "electric_pulse" then
        -- Ignore the pulse if parent-child relationship is not set, nor if the
        -- received pulse is from parent nor from an already connected soma.
        if sourceID==parent_id or parent_id==-1 or nonvalid_somas[sourceID] then
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
    end

    if eventDescription == "assign_group" then
        init = true
        parent_id = sourceID
        movement = eventTable[1]
        -- If a 0 is received, the growth cone is static and does not grow
        if movement == 0 then
            connected = true
        end
        -- Retrieve the list of somas that have already been wired to the neuron
        nonvalid_somas = eventTable[2]
        Event.emit{speed=0,description="cone_parent",
                   table={["cone_id"]=ID, ["parent_id"]=sourceID}}
    end

    if eventDescription == "excited_neuron" then
        if sourceID == parent_id then
            excited = true
            excited_neuron_time = absolute_time
            for key, values in pairs(received_pulses) do
                pulse_time = values[4]
                local intensity = values[3]
                time_diff = excited_neuron_time - pulse_time
                if time_diff > min_time_diff and time_diff < max_time_diff then
                    -- Hebbian rule positive side
                    intensity = intensity * amp * math.exp(
                            -math.abs(time_diff)/tau)
                else
                    intensity = intensity * 0.01
                end
                pulses_table[key] = {values[1], values[2], intensity, values[4]}
            end
        end
    end
end


function create_spine_agent()
    -- Evaluate distance to the last created spine agent, and create new one
    -- if distance is big enough
    coords.x1 = PositionX
    coords.y1 = PositionY
    local distance = Math.calcDistance(coords)
    -- When the growth cone has travelled enough distance, a new spine segment
    -- agent is created.
    if distance > spine_link_length then
        if not initial_spine_link then
            new_agent = Agent.addAgent("spine.lua", coords.x2, coords.y2)
        else
            initial_spine_link = false
        end
        coords.x2 = PositionX
        coords.y2 = PositionY
	end
end


function get_acceleration(ax_drag, ay_drag)
    local ax = ax_drag
    local ay = ay_drag
    if not connected then
        for key, values in pairs(pulses_table) do
            dx = values[1] - PositionX
            dy = values[2] - PositionY
            distance = math.sqrt(math.pow(dx, 2)+math.pow(dy, 2))
            if distance < 3 then
                connected = true
                Event.emit{speed=0, description="cone_connected",
                           table={key, parent_id}}
                if parent_id==analyzed_soma and record_kinematics then
                    Event.emit{speed=0, description="cone_kinematics",
                               table=kinematics_table}
                end
            end
            -- Calculate the unit vector pointing towards the source
            orientationX = dx / math.pow(distance, 2)
            orientationY = dy / math.pow(distance, 2)
            -- Get the velocity vector
            ax = ax + orientationX*values[3]
            ay = ay + orientationY*values[3]
        end
        -- Environment noise.
        local env_noise_angle = Stat.randomFloat(0, 2*math.pi)
        local env_noise_amp = Stat.gaussianFloat(0, env_noise_var)
        local env_noise_x = env_noise_amp*math.cos(env_noise_angle)
        local env_noise_y = env_noise_amp*math.sin(env_noise_angle)
        ax = ax + env_noise_x
        ay = ay + env_noise_y
    else
        ax = 0
        ay = 0
    end
    return ax, ay
end


function get_drag_force(vx, vy)
    -- Get the modulus of the drag force.
    fx_d = math.pow(vx, 2) * drag_coef
    fy_d = math.pow(vy, 2) * drag_coef
    -- Change the sign for positive speeds.
    if vx >0 then
        fx_d = -fx_d
    end
    if vy >0 then
        fy_d = -fy_d
    end
    return fx_d, fy_d
end


function cleanUp()
end
