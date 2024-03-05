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
    _V400 = 390, -- init value - must be calibrated in mv
    _V40000 = 150,-- init value - must be calibrated in mv
    _V1000 = 305,-- init value - must be calibrated in mv
    number_of_reads = 100,
    v_a_factor = -0.24373782, -- adc calibration minimum square times factor
    v_b_factor = 1054.445720, -- adc calibration minumim square added value 
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

--calibrate sensor using voltage at 400 and 40.000 ppm 
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
    cuentas = sum / M.number_of_reads
    return  cuentas, cuentas* M.v_a_factor + M.v_b_factor
end
-- returns read in ppm currently with 1000 ppm. 
function M.read()
--[[
The MG-811 sensor is basically a cell which gives an output in the range of 
100-600mV (400—10000ppm CO2). The current sourcing capability of the cell is 
quite limited. The amplitude of the signal is so low and the output impedance 
of the cell is so high that a signal conditioning circuit is required between 
the sensor and microcontroller’s ADC input. The output voltage of the sensor in
clean air (typically 400ppm CO2) is in the range of 200mV-600mV, this output 
voltage is defined as Zero Point Voltage (V­0) which is the baseline voltage. 
The output voltage will decrease as the CO2 concentration increases. When the 
concentration of CO2 is greater than 400ppm, the output voltage (Vs) is linear 
to the common logarithm of the CO2 concentration (CCO2):

Vs = V­0 +ΔVs / (log10 400 – log10 1000) * (log10 CCO2 – log10 400)

WhereΔVs = sensor output@400ppm – sensor output@1000ppm

Reaction Voltage(ΔVs) is the voltage drop from CO2 concentration of 400ppm to 
CO2 concentration of 1000ppm, which may differ from sensor to sensor. The 
typical value forΔVs is 30mV-90mV. In order to get an accurate CO2 
concentration result, proper calibration is required.
]]--
    cuentas, tension = M.raw()
    local buffer = 0;
    buffer = (math.log10(400) - math.log10(1000)) --  Delta V
    buffer = (M._V400 - M._V1000 ) / buffer
    buffer = (tension - M._V400) / buffer;
    buffer = buffer + math.log10(400);
    buffer = math.pow(10, buffer);
    return buffer
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
