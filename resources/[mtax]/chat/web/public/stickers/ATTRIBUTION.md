# Stickers

The `.svg` files in this folder are **Twemoji** graphics.

- Source: <https://github.com/jdecked/twemoji> (mirrored on npm as `@discordapp/twemoji`)
- Copyright 2020 Twitter, Inc and other contributors
- Graphics licensed under **CC-BY 4.0**: <https://creativecommons.org/licenses/by/4.0/>

Each file is named after the emoji code point it draws, which is also the id used
in `Config.Stickers` (`config.lua`). To add a sticker, drop `<codepoint>.svg` here
and add the same id to that list — the server refuses any id that is not on it, so
a client cannot make the UI load an arbitrary path.
