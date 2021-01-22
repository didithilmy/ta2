local jwt = require 'jwt'

local function foo(txn, cookie)
    local token = txn.sf:req_cook('webqueue_ticket')
    local payload = jwt.jwtverify(token, 'secret')
end

core.register_action("foo_action", { 'http-req', 'http-res' }, foo, 1)
