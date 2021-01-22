local jwt = require 'jwt'

recorded_response_times = {}

local function webqueue_request_controller(txn)
    local token = txn.sf:req_cook('webqueue_ticket')
    local payload = jwt.jwtverify(token, 'secret')
end

core.register_action("webqueue_request_controller", {'http-req', 'http-res'}, webqueue_request_controller, 0)

local function webqueue_start_request(txn)
    txn:set_priv(core.now().usec)
end

core.register_action("webqueue_start_request", {'http-req'}, webqueue_start_request, 0)

local function webqueue_end_request(txn)
    local start_time = txn:get_priv()
    local end_time = core.now().usec

    local response_time_microsec = end_time - start_time
    table.insert(recorded_response_times, response_time_microsec)

    txn.http:res_add_header('X-Response-Time-Microsec', response_time_microsec)
end

core.register_action("webqueue_end_request", {'http-res'}, webqueue_end_request, 0)
