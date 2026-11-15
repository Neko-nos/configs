local task
local relaunchPID

local function startChatGPT()
    task = hs.task
        .new("/Applications/ChatGPT.app/Contents/Resources/cua_node/bin/node", function(exitCode, _, errorOutput)
            task = nil
            if exitCode ~= 0 then
                print(errorOutput)
            end
        end, { hs.configdir .. "/chatgpt_selection.mjs" })
        :start()
end

local function applicationEvent(_, event, app)
    if not app then
        return
    end
    if event == hs.application.watcher.terminated then
        if app:pid() == relaunchPID then
            relaunchPID = nil
            startChatGPT()
        end
    elseif
        event == hs.application.watcher.launching
        and app:bundleID() == "com.openai.codex"
        and not (task and task:isRunning())
    then
        -- The private styling connection must be opened when ChatGPT starts.
        relaunchPID = app:pid()
        app:kill()
    end
end

return {
    watcher = hs.application.watcher.new(applicationEvent):start(),
}
