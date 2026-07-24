function Mod:init()
    print("Loaded " .. self.info.name .. "!")
end

function Mod:onRegisterEditorObjects()
    Registry.registerEditorObject("mouseholeentry", modRequire("scripts.editor.objects.mouseholeentry"))
    Registry.registerEditorObject("climbshooter", modRequire("scripts.editor.objects.climbshooter"))
end
