-- Ref: https://github.com/je-nunez/measuring_delays_in_backends_using_Lua_in_HAProxy
--
core.register_fetches("tstamp_microsecs", function(txn)
    local currentTimestamp = core.now()
    local tstamp_int = currentTimestamp.sec * 1000000 + currentTimestamp.usec
    return tstamp_int
end)
