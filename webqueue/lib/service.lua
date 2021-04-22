local function queue_page(applet)
    -- If client is POSTing request, receive body
    -- local request = applet:receive()

    local response = string.format([[
        <html>
            <head>
                <meta http-equiv="refresh" content="5" />
            </head>
            <body>%s</body>
        </html>
    ]], "Antrean sistem")

    applet:set_status(503)
    applet:add_header("content-length", string.len(response))
    applet:add_header("content-type", "text/html")
    applet:start_response()
    applet:send(response)
end

core.register_service("queue_page", "http", queue_page)
