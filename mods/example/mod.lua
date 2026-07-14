function Mod:init()
    Mod.logger = Logger("Example Project", ConsoleFormats.GREEN)
    Mod.logger:info("Loaded " .. self.info.name .. "!")
end
