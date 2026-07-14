function Mod:init()
    Mod.logger = Logger("Example Project", ConsoleFormats.GREEN)
    Mod.logger:info("Loaded " .. self.info.name .. "!")
end

function Mod:onRegisterEditorEvents()
    Registry.registerEditorEvent("mouseholeentry", modRequire("scripts.editor.events.mouseholeentry"))
    Registry.registerEditorEvent("climbshooter", modRequire("scripts.editor.events.climbshooter"))
end
