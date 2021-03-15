local jwt = require 'utils.jwt'

local function getTimestamp()
    local currentTimestamp = core.now()
    local tstamp_int = currentTimestamp.sec * 1000000 + currentTimestamp.usec
    return tstamp_int
end

core.register_action("webqueue_token_checker", {'http-req'}, function(txn)
    txn:set_var("req.should_queue", false)
    txn:set_var("txn.should_queue", false)
    txn:set_var("txn.should_issue_queue", false)
    txn:set_var("txn.should_issue_entry", false)

    -- Don't check token if queueing is disabled
    if webqueue_queueing_mode_enabled == false then
        return
    end

    local token = txn.sf:req_cook(WEBQUEUE_TICKET_COOKIE_NAME)
    local actual_session_id = txn.sf:req_cook(WEBQUEUE_SESSION_COOKIE_NAME)
    txn:set_var("txn.actual_session_id", actual_session_id)

    local payload = jwt.jwtverify(token, 'secret')

    if payload == false then
        txn:set_var("txn.should_issue_queue", true)
        txn:set_var("txn.should_queue", true)
        txn:set_var("req.should_queue", true)
        return
    end

    local token_type = payload.typ
    local session_id = payload.sid

    local token_valid = (session_id == actual_session_id) and (token_type == "q" or token_type == "e")
    if token_valid == false then
        txn:set_var("txn.should_issue_queue", true)
        txn:set_var("txn.should_queue", true)
        txn:set_var("req.should_queue", true)
        return
    end

    if token_type == "q" then
        local queue_no = payload.qno
        if queue_no <= webqueue_max_allowed_queue_no then
            txn:set_var("txn.should_issue_entry", true)
        else
            txn:set_var("txn.should_queue", true)
            txn:set_var("req.should_queue", true)
        end
        return
    end
end, 0)

core.register_action("webqueue_token_issuer", {'http-res'}, function(txn)
    local should_issue_entry = txn:get_var("txn.should_issue_entry")
    local actual_session_id = txn:get_var("txn.actual_session_id")

    if should_issue_entry == 1 then
        core.Debug("[!] Issuing entry token")
        local exp = core.now().sec + WEBQUEUE_ENTRY_TICKET_EXPIRY_SECS
        local payload = {
            typ = "e",
            sid = actual_session_id,
            exp = exp
        }
        local jwt_value = jwt.sign(payload, "secret")
        txn.http:res_add_header('Set-Cookie', WEBQUEUE_TICKET_COOKIE_NAME .. "=" .. jwt_value)
    end

    local should_issue_queue = txn:get_var("txn.should_issue_queue")
    if should_issue_queue == 1 then
        core.Debug("[!] Issuing queue token")
        local queue_no = webqueue_latest_issued_queue_no + 1
        webqueue_latest_issued_queue_no = queue_no
        local payload = {
            typ = "q",
            sid = actual_session_id,
            qno = webqueue_latest_issued_queue_no
        }
        local jwt_value = jwt.sign(payload, "secret")
        txn.http:res_add_header('Set-Cookie', WEBQUEUE_TICKET_COOKIE_NAME .. "=" .. jwt_value)
    end
end, 0)

core.register_action("webqueue_http_request", {'http-req', 'tcp-req'}, function(txn)
    local start_tstamp = getTimestamp()
    txn:set_var('txn.start_timestamp', start_tstamp)
end, 0)

core.register_action("webqueue_http_response", {'http-res', 'tcp-res'}, function(txn)
    local should_queue = txn:get_var("txn.should_queue")
    if should_queue == 1 then
        return
    end

    local start_tstamp = txn:get_var("txn.start_timestamp")
    local exit_tstamp = getTimestamp()

    if type(start_tstamp) ~= nil and type(exit_tstamp) ~= nil then
        local start_tstamp_num = start_tstamp
        local exit_tstamp_num = exit_tstamp
        local backend_delay_microseconds = exit_tstamp_num - start_tstamp_num
        table.insert(webqueue_recorded_response_times, backend_delay_microseconds)
        -- txn.http:res_add_header('X-Response-Time-Microsec', backend_delay_microseconds)
    end
end, 0)
