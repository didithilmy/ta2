local stats = require "utils.stats"

local TICK_DURATION_MS = 1000

local function calc_average(arr_response_time)
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
        local average = calc_average(webqueue_recorded_response_times)
        local median = stats.median(webqueue_recorded_response_times)
        local q3 = stats.q3(webqueue_recorded_response_times)
        local max, min = stats.maxmin(webqueue_recorded_response_times)

        local no_of_sessions = #webqueue_recorded_response_times

        webqueue_recorded_response_times = {}

        core.Info('Sessions: ' .. no_of_sessions .. ', Average response time: ' .. average .. ', Median: ' .. median ..
                      ', Q3: ' .. q3 .. ', Max: ' .. max .. ', Min: ' .. min)
    end
end

core.register_task(monitoring_daemon)
