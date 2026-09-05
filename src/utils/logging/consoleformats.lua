--- Default console formatting options for logging.
---
--- If you'd like something that isn't available here, make your own instance of [`ConsoleFormatting`](lua://ConsoleFormatting) and use that instead.
---@enum ConsoleFormats
return {
    DEFAULT = ConsoleFormatting({ 1, 1, 1 }, { EscapeSequences.FOREGROUND_DEFAULT }),
    BLACK = ConsoleFormatting({ 0, 0, 0 }, { EscapeSequences.FOREGROUND_BLACK }),
    GRAY = ConsoleFormatting({ 0.75, 0.75, 0.75 }, { EscapeSequences.BRIGHT_FOREGROUND_BLACK }),
    BLUE = ConsoleFormatting({ 0.5, 0.5, 1 }, { EscapeSequences.FOREGROUND_BLUE }),
    GREEN = ConsoleFormatting({ 0.5, 1, 0.5 }, { EscapeSequences.FOREGROUND_GREEN }),
    CYAN = ConsoleFormatting({ 0.5, 1, 1 }, { EscapeSequences.FOREGROUND_CYAN }),
    MAGENTA = ConsoleFormatting({ 1, 0.5, 1 }, { EscapeSequences.FOREGROUND_MAGENTA }),
    YELLOW = ConsoleFormatting({ 1, 1, 0.5 }, { EscapeSequences.FOREGROUND_YELLOW }),
    RED = ConsoleFormatting({ 1, 0.5, 0.5 }, { EscapeSequences.FOREGROUND_RED }),
    FATAL = ConsoleFormatting({ 1, 0, 0 }, {
        EscapeSequences.FOREGROUND_BLACK,
        EscapeSequences.BACKGROUND_RED
    })
}
