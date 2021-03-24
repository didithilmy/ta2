local random = {}

local upperCase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
local lowerCase = "abcdefghijklmnopqrstuvwxyz"
local numbers = "0123456789"

local characterSet = upperCase .. lowerCase .. numbers

function random.generateRandomSecret(keyLength)
    local output = ""

    for i = 1, keyLength do
        local rand = math.random(#characterSet)
        output = output .. string.sub(characterSet, rand, rand)
    end

    return output
end

return random