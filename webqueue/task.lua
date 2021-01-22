local TICK_DURATION_MS = 5000

local function calc_positive_average(arr_response_time)
    local sum, n = 0, 0
    for k, v in ipairs(arr_response_time) do
        if (v > 0) then
            sum = sum + v
            n = n + 1
        end
    end

    if n == 0 then
        return 0
    end

    return sum / n
end

local function monitoring_daemon()
    while true do
        core.msleep(TICK_DURATION_MS)
        local average = calc_positive_average(recorded_response_times)
        recorded_response_times = {}
        core.Debug('Average response time: ' .. average)
    end
end

core.register_task(monitoring_daemon)
