--
-- JWT Validation implementation for HAProxy Lua host
--
-- Copyright (c) 2019. Adis Nezirovic <anezirovic@haproxy.com>
-- Copyright (c) 2019. Baptiste Assmann <bassmann@haproxy.com>
-- Copyright (c) 2019. Nick Ramirez <nramirez@haproxy.com>
-- Copyright (c) 2019. HAProxy Technologies LLC
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Use HAProxy 'lua-load' to load optional configuration file which
-- should contain config table.
-- Default/fallback config
local jwt = {}

local json = require 'json'
local base64 = require 'utils.base64'
local openssl = {
    pkey = require 'openssl.pkey',
    digest = require 'openssl.digest',
    x509 = require 'openssl.x509',
    hmac = require 'openssl.hmac'
}

local function log(msg)
    -- core.Debug(tostring(msg))
end

local function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

function jwt.readAll(file)
    log("Reading file " .. file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

local function decodeJwt(jwt_string)
    local headerFields = core.tokenize(jwt_string, " .")
    
    log('JWT string: ' .. jwt_string)

    if #headerFields ~= 3 then
        log("Improperly formated Authorization header. Should be 3 token sections.")
        return nil
    end

    local token = {}
    token.header = headerFields[1]
    token.headerdecoded = json.decode(base64.decode(token.header))

    token.payload = headerFields[2]
    token.payloaddecoded = json.decode(base64.decode(token.payload))

    token.signature = headerFields[3]
    token.signaturedecoded = base64.decode(token.signature)

    log('JWT string: ' .. jwt_string)
    log('Decoded JWT header: ' .. dump(token.headerdecoded))
    log('Decoded JWT payload: ' .. dump(token.payloaddecoded))

    return token
end

local function algorithmIsValid(token)
    if token.headerdecoded.alg == nil then
        log("No 'alg' provided in JWT header.")
        return false
    elseif token.headerdecoded.alg ~= 'HS256' then
        log("HS256 supported. Incorrect alg in JWT: " .. token.headerdecoded.alg)
        return false
    end

    return true
end

local function hs256SignatureIsValid(token, secret)
    local hmac = openssl.hmac.new(secret, 'SHA256')
    local checksum = hmac:final(token.header .. '.' .. token.payload)
    return checksum == token.signaturedecoded
end

local function expirationIsValid(token)
    if token.payloaddecoded.exp == nil then
        return true
    end
    return os.difftime(token.payloaddecoded.exp, core.now().sec) > 0
end

local function issuerIsValid(token, expectedIssuer)
    if token.payloaddecoded.iss == nil then
        return true
    end
    return token.payloaddecoded.iss == expectedIssuer
end

local function audienceIsValid(token, expectedAudience)
    if token.payloaddecoded.aud == nil then
        return true
    end
    return token.payloaddecoded.aud == expectedAudience
end

function jwt.jwtverify(jwt_string, hmac_secret)

    -- 1. Decode and parse the JWT
    local token = decodeJwt(jwt_string)

    if token == nil then
        log("Token could not be decoded.")
        goto out
    end

    -- 2. Verify the signature algorithm is supported (HS256)
    if algorithmIsValid(token) == false then
        log("Algorithm not valid.")
        goto out
    end

    -- 3. Verify the signature with the certificate
    if token.headerdecoded.alg == 'HS256' then
        if hs256SignatureIsValid(token, hmac_secret) == false then
            log("Signature not valid.")
            goto out
        end
    end

    -- 4. Verify that the token is not expired
    if expirationIsValid(token) == false then
        log("Token is expired.")
        goto out
    end

    -- exit
    do
        return token.payloaddecoded
    end

    -- way out. Display a message when running in debug mode
    ::out::
    log("req.authorized = false")
    return false
end

return jwt
