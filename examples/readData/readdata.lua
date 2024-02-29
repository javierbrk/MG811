a1 = 0
a2 = 0
a3 = 0
a4 = 0
a5 = 0
adc.setup(adc.ADC1,0,adc.ATTEN_0db)

sensor=require('MG811')
print(sensor.raw())

mytimer = tmr.create()
mytimer:register(2000, tmr.ALARM_AUTO, function() 
    a6 = adc.read(adc.ADC1,0)
    average = (a1+a2+a3+a4+a5+a6)/6    
    voltage = average*-0.25591+1092.6924
    print ("cuentas ".. average.. " tension "..voltage )
    
    a1=a2
    a2=a3
    a3=a4
    a4=a5
    a5=a6    
    sum = 0
    
    for i= 1, 10 do
       sum =  sum + adc.read(adc.ADC1,0)
    end
    print("cuentas " .. sum/10)

    print("sensor raw ".. sensor.raw())
    print("sensor read ".. sensor.read())
    
    
end)
mytimer:start()