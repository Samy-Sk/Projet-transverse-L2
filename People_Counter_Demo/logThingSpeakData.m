% logThingSpeakData
% This function is used by PeopleCounterDemo.m to write data to a
% ThingSpeak channel. 
%
% Copyright 2016 The MathWorks, Inc

function logThingSpeakData(totalEntry)

channelID = 1731876;
writeKey = 'PA8LFRO2UZPHOOTB';
    
    try
    thingSpeakWrite(channelID,totalEntry,'WriteKey',writeKey,'Timeout',5)
    catch

    end
end

