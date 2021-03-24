local stats = require "utils.stats"
local random = require "utils.random"

local TICK_DURATION_MS = 1000
local RESPONSE_TIME_THRESHOLD_MS = 500
local CONSEQUENT_ABOVE_THRESHOLD_ENABLE_QUEUEING = 2
local CONSEQUENT_BELOW_THRESHOLD_ADMIT_NEW = 10
local CONSEQUENT_BELOW_THRESHOLD_DISABLE_QUEUEING = 20
local ADMITTANCE_INCREMENT = 30

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

local function enableQueueing()
    local secret = random.generateRandomSecret(32)
    webqueue_jwt_signing_secret = secret
    webqueue_queueing_mode_enabled = true
    core.Info("Queueing enabled, secret=" .. secret)
end

local function disableQueueing()
    webqueue_queueing_mode_enabled = false
    core.Info("Queueing disabled")
end

local function admitNewSessions()
    webqueue_max_allowed_queue_no = webqueue_max_allowed_queue_no + ADMITTANCE_INCREMENT
end

local function evaluate_threshold()
    if webqueue_queueing_mode_enabled == false then
        if webqueue_consequent_n_above_threshold >= CONSEQUENT_ABOVE_THRESHOLD_ENABLE_QUEUEING then
            enableQueueing()
        end
    else
        if webqueue_consequent_n_below_threshold >= CONSEQUENT_BELOW_THRESHOLD_DISABLE_QUEUEING then
            disableQueueing()
        elseif webqueue_consequent_n_below_threshold >= CONSEQUENT_BELOW_THRESHOLD_ADMIT_NEW then
            admitNewSessions()
        end
    end
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

        if average < RESPONSE_TIME_THRESHOLD_MS then
            webqueue_consequent_n_above_threshold = 0
            if webqueue_queueing_mode_enabled then
                webqueue_consequent_n_below_threshold = webqueue_consequent_n_below_threshold + 1
            end
        else
            webqueue_consequent_n_below_threshold = 0
            webqueue_consequent_n_above_threshold = webqueue_consequent_n_above_threshold + 1
        end

        evaluate_threshold()

        core.Info('Sessions: ' .. no_of_sessions .. ', Average response time: ' .. average .. ', Median: ' .. median ..
                      ', Q3: ' .. q3 .. ', Max: ' .. max .. ', Min: ' .. min)
    end
end

core.register_task(monitoring_daemon)
