local jwt = require 'utils.jwt'

webqueue_recorded_response_times = {}

local function getTimestamp()
    local currentTimestamp = core.now()
    local tstamp_int = currentTimestamp.sec * 1000000 + currentTimestamp.usec
    return tstamp_int
end

core.register_action("webqueue_request_controller", {'http-req', 'http-res'}, function(txn)
    local token = txn.sf:req_cook('webqueue_ticket')
    local payload = jwt.jwtverify(token, 'secret')
end, 0)

core.register_action("webqueue_http_request", {'http-req'}, function(txn)
    local start_tstamp = getTimestamp()
    txn:set_var('txn.start_timestamp', start_tstamp)
end, 0)

core.register_action("webqueue_http_response", {'http-res'}, function(txn)
    local start_tstamp = txn:get_var("txn.start_timestamp")
    local exit_tstamp = getTimestamp()

    if type(start_tstamp) ~= nil and type(exit_tstamp) ~= nil then
        local start_tstamp_num = start_tstamp
        local exit_tstamp_num = exit_tstamp
        local backend_delay_microseconds = exit_tstamp_num - start_tstamp_num
        table.insert(webqueue_recorded_response_times, backend_delay_microseconds)
        txn.http:res_add_header('X-Response-Time-Microsec', backend_delay_microseconds)
    end
end, 0)
