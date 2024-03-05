sensor=require('MG811')
sensor.read()

mytimer = tmr.create()
mytimer:register(2000, tmr.ALARM_AUTO, function() 
    cuentas, tension = sensor.raw()
    print("sensor raw "..cuentas .. " ".. tension)
    print("sensor read ".. sensor.read())
   
end)
mytimer:start()
