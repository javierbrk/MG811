--[[
  Mg811.lua for ESP32 with nodemcu-firmware
  Read adc and convert to ppm

   Written by Javier translated from oginal repo
]] local M = {
    name = ..., -- module name, upvalue from require('module-name')
    model = "MG811", -- sensor model
    verbose = false, -- verbose output
    debug = nil, -- additional ckecks
    ADC_chanel = 0, -- integer value must be one of the posible adc chanles availables
    _V400 = 800, -- init value - must be calibrated in mv
    _V40000 = 100, -- init value - must be calibrated in mv
    number_of_reads = 50,
    v_a_factor = -0.25591,
    v_b_factor = 1092.6924,
    mytimer = {}
}
_G[M.name] = M

local is_int = function(n)
    return (type(n) == "number") and (math.floor(n) == n)
end

-- initialize module
function M.MG811(chanel)
    if chanel ~= nil and is_int(chanel) then
        ADC_chanel = chanel
    end
    adc.setup(adc.ADC1, ADC_chanel, adc.ATTEN_0db)
end

function M.begin(V400, V40000)
    if V400 ~= nil and is_int(V400) then
        M._V400 = V400
    end
    if V40000 ~= nil and is_int(V40000) then
        M._V40000 = V40000
    end
end
-- returns mv from adc
-- compensates counts using minimum square adjustment
function M.raw()
    local sum = 0
    for i = 1, M.number_of_reads do
        sum = sum + adc.read(adc.ADC1, 0)
    end
    return sum / M.number_of_reads * M.v_a_factor + M.v_b_factor
end
-- returns read in ppm
function M.read()
    local buffer = 0;
    buffer = (M._V400 - M._V40000) / (math.log10(400) - math.log10(40000)) --  Delta V
    buffer = (M.raw() - M._V400) / buffer;
    buffer = buffer + math.log10(400);
    return math.pow(10, buffer);
end

--[[
    function: calibrate
    @summary: calibrate the sensor to get reference value for measurement
              
              Power on the sensor
              
              [0] Put the sensor outdoor or indoor with good ventilation
                  Wait at least two (02) hours - for warming up
                  Read it's measurement - You get 400ppm reference voltage
              
              [1] Put the sensor in a bag filled with exhaled air
                  Wait a couple of minutes
                  Read it's measurement - You get 40000ppm reference voltage
              
              The reference value measured by this function should be used with 
              the `begin` method in order to use tthe sensor
              
    @see: this function needs Serial communication to be enabled to print out   
          information
          
          Serial.begin(9600)
    @parameter: none
    @return: none
	]] --
function M.calibrate()
    M.mytimer = tmr.create()
    print("Time (mn) \t\t Measurement (volt)");
    M.mytimer:register(5000, tmr.ALARM_AUTO, function()
        M.i = i + 5
        print(M.i .. " " .. raw())
    end)
    M.mytimer:start()
end

return M
