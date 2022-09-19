C_Timer = { };

function C_Timer.After(duration, callback)
    ezCollections.AceAddon:ScheduleTimer(callback, duration);
end
