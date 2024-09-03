local SchoolDoor, super = Class(Map)

function SchoolDoor:load()
    super.load(self)

    Game:setPartyMembers("kris", "susie")
end

return SchoolDoor