return {
    "gelguy/wilder.nvim",
    dependencies = { "romgrk/fzy-lua-native" },
    config = function()
        local wilder = require("wilder")
        wilder.setup({
            modes = { ":", "/", "?" },
            next_key = "<Down>",
            previous_key = "<Up>",
            accept_key = "<Tab>",
            reject_key = "<S-Tab>",
        })

        wilder.set_option("pipeline", {
            wilder.branch(
                wilder.cmdline_pipeline({
                    -- sets the language to use, 'vim' and 'python' are supported
                    language = "python",
                    -- 0 turns off fuzzy matching
                    -- 1 turns on fuzzy matching
                    -- 2 partial fuzzy matching (match does not have to begin with the same first letter)
                    fuzzy = 2,
                    fuzzy_filter = wilder.lua_fzy_filter(),
                }),
                wilder.python_search_pipeline({
                    -- can be set to wilder#python_fuzzy_delimiter_pattern() for stricter fuzzy matching
                    pattern = wilder.python_fuzzy_pattern(),
                    -- omit to get results in the order they appear in the buffer
                    sorter = wilder.python_difflib_sorter(),
                    -- can be set to 're2' for performance, requires pyre2 to be installed
                    -- see :h wilder#python_search() for more details
                    engine = "re2",
                })
            ),
        })
        wilder.set_option(
            "renderer",
            wilder.renderer_mux({
                [":"] = wilder.popupmenu_renderer(wilder.popupmenu_palette_theme({
                    -- 'single', 'double', 'rounded' or 'solid'
                    -- can also be a list of 8 characters, see :h wilder#popupmenu_palette_theme() for more details

                    highlighter = {
                        wilder.lua_pcre2_highlighter(),
                        wilder.lua_fzy_highlighter(),
                    },
                    highlights = {
                        accent = wilder.make_hl(
                            "WilderAccent",
                            "Pmenu",
                            { { a = 1 }, { a = 1 }, { foreground = "#f4468f" } }
                        ),
                    },
                    pumblend = 30,
                    border = "rounded",
                    max_height = "25%", -- max height of the palette
                    min_height = 0, -- set to the same as 'max_height' for a fixed height window
                    prompt_position = "top", -- 'top' or 'bottom' to set the location of the prompt
                    reverse = 0, -- set to 1 to reverse the order of the list, use in combination with 'prompt_position'
                    left = { " ", wilder.popupmenu_devicons() },
                    right = { " ", wilder.popupmenu_spinner({ delay = 0 }), wilder.popupmenu_scrollbar() },
                })),
                ["/"] = wilder.wildmenu_renderer({
                    highlighter = {
                        wilder.lua_pcre2_highlighter(),
                        wilder.lua_fzy_highlighter(),
                    },
                    highlights = {
                        accent = wilder.make_hl(
                            "WilderAccent",
                            "Pmenu",
                            { { a = 1 }, { a = 1 }, { foreground = "#f4468f" } }
                        ),
                    },
                    pumblend = 30,
                }),
            })
        )
    end,
}
