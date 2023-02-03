local QuicksaveEvent, super = Class(Event)

function QuicksaveEvent:init(x, y, w, h, marker)
    super.init(self, x, y, w, h)
    self.marker = marker
end

function QuicksaveEvent:onEnter()
    Game:saveQuick(self.marker)
end

return QuicksaveEvent