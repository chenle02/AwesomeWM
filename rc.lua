--[[
     Awesome WM configuration template
     github.com/lcpz

--]]

-- {{{ Required libraries
local awesome, client, mouse, screen, tag = awesome, client, mouse, screen, tag
local ipairs, string, os, table, tostring, tonumber, type = ipairs, string, os, table, tostring, tonumber, type

local gears         = require("gears")
local awful         = require("awful")
                      require("awful.autofocus")
local wibox         = require("wibox")
local beautiful     = require("beautiful")
local naughty       = require("naughty")
local lain          = require("lain")
local vertical      = require("vertical_layout")
-- local menubar       = require("menubar")
local freedesktop   = require("freedesktop")
local hotkeys_popup = require("awful.hotkeys_popup").widget
                      require("awful.hotkeys_popup.keys")
local my_table      = awful.util.table or gears.table -- 4.{0,1} compatibility
local dpi           = require("beautiful.xresources").apply_dpi
-- local battery_widget = require("awesome-wm-widgets.battery-widget.battery")

-- The following is for VPN
-- Ref: https://github.com/letsluk/awesome-wm-widgets
-- local vpn	    = require("vpn")
-- local xrandr	    = require("xrandr")

-- }}}

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- https://stackoverflow.com/questions/29681677/always-on-top-window-and-keeping-focus-on-awesomewm
-- Always-on-top window, Step 3-1: define a function{{{
-- Failed
-- function custom_focus_filter(c)
--     if global_focus_disable then
--         return nil
--     end
--     return awful.client.focus.filter(c)
-- end
--}}}

-- {{{ Autostart windowless processes

-- This function will run once every time Awesome is started
local function run_once(cmd_arr)
    for _, cmd in ipairs(cmd_arr) do
        awful.spawn.with_shell(string.format("pgrep -u $USER -fx '%s' > /dev/null || (%s)", cmd, cmd))
        awful.spawn.with_shell("lxpolkit")
    end
end

run_once({ "urxvtd", "unclutter -root" }) -- entries must be separated by commas

-- autostart
awful.spawn.with_shell("~/.config/awesome/autorun.sh")

-- This function implements the XDG autostart specification
--[[
awful.spawn.with_shell(
    'if (xrdb -query | grep -q "^awesome\\.started:\\s*true$"); then exit; fi;' ..
    'xrdb -merge <<< "awesome.started:true";' ..
    -- list each of your autostart commands, followed by ; inside single quotes, followed by ..
    'dex --environment Awesome --autostart --search-paths "$XDG_CONFIG_DIRS/autostart:$XDG_CONFIG_HOME/autostart"' -- https://github.com/jceb/dex
)
--]]

-- }}}

-- {{{ Variable definitions

local themes = {
    "blackburn",       -- 1
    "copland",         -- 2
    "dremora",         -- 3
    "holo",            -- 4
    "multicolor",      -- 5
    "powerarrow",      -- 6
    "powerarrow-dark", -- 7
    "rainbow",         -- 8
    "steamburn",       -- 9
    "vertex",          -- 10
    "duck",            -- 11
}

local chosen_theme = themes[7]
local modkey       = "Mod4"
local altkey       = "Mod1"
-- local terminal     = "terminology"
local terminal     = "urxvt"
local vi_focus     = false -- vi-like client focus - https://github.com/lcpz/awesome-copycats/issues/275
local cycle_prev   = true -- cycle trough all previous client or just the first -- https://github.com/lcpz/awesome-copycats/issues/274
local editor       = os.getenv("EDITOR") or "vim"
local gui_editor   = os.getenv("GUI_EDITOR") or "gvim"
-- local browser      = os.getenv("BROWSER") or "firefox"
local browser      = os.getenv("BROWSER") or "firefox"
local scrlocker    = "slock"

awful.util.terminal = terminal
awful.util.tagnames = { "1. Main", "2. Zoom", "3. ChatGPT", "4. Simulation", "5. Terminal-fire", "6. SPDE-Bib", "7. Email", "8. Web Browser", "9. References" }
awful.layout.layouts = {
    vertical, -- added by myself, all vertical.
    -- awful.layout.suit.floating,
    -- awful.layout.suit.tile, -- my favorite
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.right, -- Nice one to use
    -- awful.layout.suit.tile.bottom,
    -- awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    -- awful.layout.suit.spiral.dwindle,
    -- awful.layout.suit.max,
    -- awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier, -- Another nice one
    -- awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
    -- lain.layout.cascade,
    -- lain.layout.cascade.tile,
    lain.layout.centerwork, -- A nice one used for a while
    -- lain.layout.centerwork.horizontal,
    -- lain.layout.termfair,
    -- lain.layout.termfair.center,
}

awful.util.taglist_buttons = my_table.join(
    awful.button({ }, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
        if client.focus then
            client.focus:move_to_tag(t)
        end
    end),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
        if client.focus then
            client.focus:toggle_tag(t)
        end
    end),
    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

awful.util.tasklist_buttons = my_table.join(
    awful.button({ }, 1, function (c)
        if c == client.focus then
            c.minimized = true
        else
            --c:emit_signal("request::activate", "tasklist", {raise = true})<Paste>

            -- Without this, the following
            -- :isvisible() makes no sense
            c.minimized = false
            if not c:isvisible() and c.first_tag then
                c.first_tag:view_only()
            end
            -- This will also un-minimize
            -- the client, if needed
            client.focus = c
            c:raise()
        end
    end),
    awful.button({ }, 2, function (c) c:kill() end),
    awful.button({ }, 3, function ()
        local instance = nil

        return function ()
            if instance and instance.wibox.visible then
                instance:hide()
                instance = nil
            else
                instance = awful.menu.clients({theme = {width = dpi(250)}})
            end
        end
    end),
    awful.button({ }, 4, function () awful.client.focus.byidx(1) end),
    awful.button({ }, 5, function () awful.client.focus.byidx(-1) end)
)

lain.layout.termfair.nmaster           = 3
lain.layout.termfair.ncol              = 1
lain.layout.termfair.center.nmaster    = 3
lain.layout.termfair.center.ncol       = 1
lain.layout.cascade.tile.offset_x      = dpi(2)
lain.layout.cascade.tile.offset_y      = dpi(32)
lain.layout.cascade.tile.extra_padding = dpi(5)
lain.layout.cascade.tile.nmaster       = 5
lain.layout.cascade.tile.ncol          = 2

beautiful.init(string.format("%s/.config/awesome/themes/%s/theme.lua", os.getenv("HOME"), chosen_theme))
-- }}}

-- {{{ Menu
local myawesomemenu = {
    { "hotkeys", function() return false, hotkeys_popup.show_help end },
    { "manual", terminal .. " -e man awesome" },
    { "edit config", string.format("%s -e %s %s", terminal, editor, awesome.conffile) },
    { "restart", awesome.restart },
    { "quit", function() awesome.quit() end }
}
awful.util.mymainmenu = freedesktop.menu.build({
    icon_size = beautiful.menu_height or dpi(16),
    before = {
        { "Awesome", myawesomemenu, beautiful.awesome_icon },
        -- other triads can be put here
    },
    after = {
        { "Open terminal", terminal },
        -- other triads can be put here
    }
})
-- hide menu when mouse leaves it
--awful.util.mymainmenu.wibox:connect_signal("mouse::leave", function() awful.util.mymainmenu:hide() end)

--menubar.utils.terminal = terminal -- Set the Menubar terminal for applications that require it
-- }}}

-- {{{ Screen
-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", function(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end)

-- No borders when rearranging only 1 non-floating or maximized client
screen.connect_signal("arrange", function (s)
    local only_one = #s.tiled_clients == 1
    for _, c in pairs(s.clients) do
        if only_one and not c.floating or c.maximized then
            c.border_width = 0
        else
            c.border_width = beautiful.border_width
        end
    end
end)
-- Create a wibox for each screen and add it
awful.screen.connect_for_each_screen(function(s) beautiful.at_screen_connect(s) end)

-- Create one instance of quake for each screen
-- https://github.com/lcpz/lain/wiki/Utilities#quake
-- https://www.reddit.com/r/awesomewm/comments/5s9zwk/help_awesome_4lain_dropdown_terminal_and_dual/
awful.screen.connect_for_each_screen(function(s)
    -- Quake application
    s.quake = lain.util.quake({app = "urxvt", followtag = true, height = 0.5, overlap = true})
    -- s.quake = lain.util.quake { settings = function(c) c.sticky = true end }
    -- [...]
    end)
-- }}}

-- Create the wibox
--  s.mywibox = awful.wibar({ position = "bottom", screen = s })
--  s.mywibox:setup {
--  layout = wibox.layout.align.horizontal,
--  }

-- {{{ Mouse bindings
root.buttons(my_table.join(
    awful.button({ }, 3, function () awful.util.mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings

-- {{{ First, globalkeys:
globalkeys = my_table.join(
    -- Take a screenshot
    -- https://github.com/lcpz/dots/blob/master/bin/screenshot
    -- awful.key({ altkey }, "p", function() os.execute("gnome-screenshot") end,
              -- {description = "take a screenshot", group = "hotkeys"}),
    -- awful.key({ altkey }, "P", function() os.execute("gnome-screenshot") end,
              -- {description = "take a screenshot", group = "hotkeys"}),

    awful.key({ modkey }, "p", function () awful.util.spawn("gnome-screenshot -ai", false) end,
    -- awful.key({ }, "Print", function () awful.util.spawn("gnome-screenshot -ai", false) end,
              {description = "take a screenshot", group = "hotkeys"}),

    -- X screen locker
    awful.key({ "Control", "Shift" }, "s", function () os.execute(scrlocker) end,
              {description = "lock screen", group = "hotkeys"}),

    -- Hotkeys
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description = "show help", group="awesome"}),
    -- Master focus
    -- https://www.reddit.com/r/awesomewm/comments/1mz3jq/create_keybinding_to_focus_master_client_in/
    -- awful.key({ modkey,          }, "e",  function() client.focus = awful.client.getmaster(); client.focus:raise() end),

    -- Add two research related keybindings
    -- awful.key({ modkey, "Shift" }, "a", function () awful.spawn.with_shell("fd --full-path --extension pdf -p 'Dropbox/All_*/*' | rofi -dmenu | xargs -I{} zathura \"{}\"") end,
    awful.key({ modkey, "Shift" }, "a", function () awful.spawn.with_shell("fd --full-path --extension pdf 'Dropbox/All_*/*' | rofi -dmenu | xargs -I{} zathura \"{}\"") end,
          {description = "open PDF in All PDFs", group = "Research"}),

    awful.key({ modkey, "Shift" }, "z", function () awful.spawn.with_shell("~/bin/OpenGoodNotes.sh yes") end,
          {description = "open PDF in Good Notes", group = "Research"}),

    -- Tag browsing
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),

    -- Non-empty tag browsing
    awful.key({ altkey }, "Left", function () lain.util.tag_view_nonempty(-1) end,
              {description = "view  previous nonempty", group = "tag"}),
    awful.key({ altkey }, "Right", function () lain.util.tag_view_nonempty(1) end,
              {description = "view  previous nonempty", group = "tag"}),

    -- Default client focus
    awful.key({ altkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ altkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),

    -- By direction client focus{{{
    awful.key({ modkey }, "j",
        function()
            awful.client.focus.global_bydirection("down")
            if client.focus then client.focus:raise() end
        end,
        {description = "focus down", group = "client"}),
    awful.key({ modkey }, "k",
        function()
            awful.client.focus.global_bydirection("up")
            if client.focus then client.focus:raise() end
        end,
        {description = "focus up", group = "client"}),
    awful.key({ modkey }, "h",
        function()
            awful.client.focus.global_bydirection("left")
            if client.focus then client.focus:raise() end
        end,
        {description = "focus left", group = "client"}),
    awful.key({ modkey }, "l",
        function()
            awful.client.focus.global_bydirection("right")
            if client.focus then client.focus:raise() end
        end,
        {description = "focus right", group = "client"}),
    awful.key({ modkey,           }, "w", function () awful.util.mymainmenu:show() end,
              {description = "show main menu", group = "awesome"}),
    --}}}

    -- Layout manipulation{{{
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            if cycle_prev then
                awful.client.focus.history.previous()
            else
                awful.client.focus.byidx(-1)
            end
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "cycle with previous/go back", group = "client"}),
    awful.key({ modkey, "Shift"   }, "Tab",
        function ()
            if cycle_prev then
                awful.client.focus.byidx(1)
                if client.focus then
                    client.focus:raise()
                end
            end
        end,
        {description = "go forth", group = "client"}),
    --}}}



    -- Always-on-top window, Step 3-3: define a keybinding{{{
    -- Failed
    -- awful.key({ modkey, "Shift" }, "f", function ()
    --     global_focus_disable = not global_focus_disable
    -- end),
    --}}}

    -- Show/Hide Wibox
    awful.key({ modkey }, "b", function ()
            for s in screen do
                s.mywibox.visible = not s.mywibox.visible
                if s.mybottomwibox then
                    s.mybottomwibox.visible = not s.mybottomwibox.visible
                end
            end
        end,
        {description = "toggle wibox", group = "awesome"}),

    -- On the fly useless gaps change{{{
    awful.key({ altkey, "Control" }, "+", function () lain.util.useless_gaps_resize(1) end,
              {description = "increment useless gaps", group = "tag"}),
    awful.key({ altkey, "Control" }, "-", function () lain.util.useless_gaps_resize(-1) end,
              {description = "decrement useless gaps", group = "tag"}),
    --}}}


    -- Dynamic tagging{{{
    awful.key({ modkey, "Shift" }, "n", function () lain.util.add_tag() end,
              {description = "add new tag", group = "tag"}),
    awful.key({ modkey, "Shift" }, "r", function () lain.util.rename_tag() end,
              {description = "rename tag", group = "tag"}),
    awful.key({ modkey, "Shift" }, "Left", function () lain.util.move_tag(-1) end,
              {description = "move tag to the left", group = "tag"}),
    awful.key({ modkey, "Shift" }, "Right", function () lain.util.move_tag(1) end,
              {description = "move tag to the right", group = "tag"}),
    awful.key({ modkey, "Shift" }, "d", function () lain.util.delete_tag() end,
              {description = "delete tag", group = "tag"}),
    --}}}

    -- Standard program{{{
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),

    awful.key({ altkey, "Shift"   }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ altkey, "Shift"   }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
              {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),

    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                      client.focus = c
                      c:raise()
                  end
              end,
              {description = "restore minimized", group = "client"}),
    --}}}

    -- Dropdown application{{{
    awful.key({ modkey, }, "z", function () awful.screen.focused().quake:toggle() end,
              {description = "dropdown application", group = "launcher"}),
    --}}}

    -- Widgets popups{{{
    awful.key({ altkey, }, "c", function () if beautiful.cal then beautiful.cal.show(7) end end,
              {description = "show calendar", group = "widgets"}),
    awful.key({ altkey, }, "h", function () if beautiful.fs then beautiful.fs.show(7) end end,
              {description = "show filesystem", group = "widgets"}),
    awful.key({ altkey, }, "w", function () if beautiful.weather then beautiful.weather.show(7) end end,
              {description = "show weather", group = "widgets"}),
    --}}}

    -- Brightness{{{
    awful.key({ }, "XF86MonBrightnessUp", function () os.execute("xbacklight -inc 10") end,
              {description = "+10%", group = "hotkeys"}),
    awful.key({ }, "XF86MonBrightnessDown", function () os.execute("xbacklight -dec 10") end,
              {description = "-10%", group = "hotkeys"}),
    --}}}

    -- ALSA volume control{{{
    awful.key({ altkey }, "Up",
        function ()
            os.execute(string.format("amixer -q set %s 1%%+", beautiful.volume.channel))
            beautiful.volume.update()
        end,
        {description = "volume up", group = "hotkeys"}),
    awful.key({ altkey }, "Down",
        function ()
            os.execute(string.format("amixer -q set %s 1%%-", beautiful.volume.channel))
            beautiful.volume.update()
        end,
        {description = "volume down", group = "hotkeys"}),
    awful.key({ altkey }, "m",
        function ()
            os.execute(string.format("amixer -q set %s toggle", beautiful.volume.togglechannel or beautiful.volume.channel))
            beautiful.volume.update()
        end,
        {description = "toggle mute", group = "hotkeys"}),
    awful.key({ altkey, "Control" }, "m",
        function ()
            os.execute(string.format("amixer -q set %s 100%%", beautiful.volume.channel))
            beautiful.volume.update()
        end,
        {description = "volume 100%", group = "hotkeys"}),
    awful.key({ altkey, "Control" }, "0",
        function ()
            os.execute(string.format("amixer -q set %s 0%%", beautiful.volume.channel))
            beautiful.volume.update()
        end,
        {description = "volume 0%", group = "hotkeys"}),
    --}}}

    -- MPD control{{{
    awful.key({ altkey, "control" }, "up",
        function ()
            os.execute("mpc toggle")
            beautiful.mpd.update()
        end,
        {description = "mpc toggle", group = "widgets"}),
    awful.key({ altkey, "control" }, "down",
        function ()
            os.execute("mpc stop")
            beautiful.mpd.update()
        end,
        {description = "mpc stop", group = "widgets"}),
    awful.key({ altkey, "control" }, "left",
        function ()
            os.execute("mpc prev")
            beautiful.mpd.update()
        end,
        {description = "mpc prev", group = "widgets"}),
    awful.key({ altkey, "control" }, "right",
        function ()
            os.execute("mpc next")
            beautiful.mpd.update()
        end,
        {description = "mpc next", group = "widgets"}),
    awful.key({ altkey }, "0",
        function ()
            local common = { text = "mpd widget ", position = "top_middle", timeout = 2 }
            if beautiful.mpd.timer.started then
                beautiful.mpd.timer:stop()
                common.text = common.text .. lain.util.markup.bold("off")
            else
                beautiful.mpd.timer:start()
                common.text = common.text .. lain.util.markup.bold("on")
            end
            naughty.notify(common)
        end,
        {description = "mpc on/off", group = "widgets"}),
    --}}}

    -- copy primary to clipboard (terminals to gtk)
    awful.key({ modkey }, "c", function () awful.spawn.with_shell("xsel | xsel -i -b") end,
              {description = "copy terminal to gtk", group = "hotkeys"}),
    -- copy clipboard to primary (gtk to terminals)
    awful.key({ modkey }, "v", function () awful.spawn.with_shell("xsel -b | xsel") end,
              {description = "copy gtk to terminal", group = "hotkeys"}),

    -- user programs
    awful.key({ modkey }, "q", function () awful.spawn(browser) end,
              {description = "run browser", group = "launcher"}),
    awful.key({ modkey }, "a", function () awful.spawn("firefox") end,
              {description = "run browser", group = "launcher"}),
    awful.key({ modkey }, "/", function () awful.spawn("synapse") end,
	      {description = "find files/app... (le)", group = "launcher"}),
    -- awful.key({ modkey }, "a", function () awful.spawn(gui_editor) end,
    --           {description = "run gui editor", group = "launcher"}),

    --[[ menubar
    awful.key({ modkey }, "p", function() menubar.show() end,
              {description = "show the menubar", group = "launcher"})
    --]]
    --[[ dmenu
    awful.key({ modkey }, "x", function ()
            os.execute(string.format("dmenu_run -i -fn 'monospace' -nb '%s' -nf '%s' -sb '%s' -sf '%s'",
            beautiful.bg_normal, beautiful.fg_normal, beautiful.bg_focus, beautiful.fg_focus))
        end,
        {description = "show dmenu", group = "launcher"})
    --]]
    -- alternatively use rofi, a dmenu-like application with more features
    -- check https://github.com/davedavenport/rofi for more details
    --[[ rofi
    awful.key({ modkey }, "x", function ()
            os.execute(string.format("rofi -show %s -theme %s",
            'run', 'dmenu'))
        end,
        {description = "show rofi", group = "launcher"}),
    --]]
    -- prompt
    -- awful.key({ modkey }, "r", function () awful.screen.focused().mypromptbox:run() end,
              -- {description = "run prompt", group = "launcher"}),
    -- awful.key({ modkey }, "r", function () awful.util.spawn("dmenu_run") end,
    --           {description = "run dmenu", group = "launcher"}),
    awful.key({ modkey }, "r", function () awful.util.spawn("rofi -combi-modi window, drun, run -show combi") end,
              {description = "run rofi", group = "launcher"}),
    -- awful.key({ modkey, "control", }, "0", function () awful.util.spawn("systemctl poweroff -i") end,
    --           {description = "Power off the system", group = "launcher"}),
    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "run lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end,
              {description = "lua execute prompt", group = "awesome"})
    --]]

    -- awful.key({ modkey, "shift" }, "x", function() xrandr.xrandr() end,
	-- 	  {description = "run xrandr for monitor settings", group = "awesome"})
) -- end of my_table.join for globalkeys
---}}}

--{{{ second, clientkeys:
clientkeys = my_table.join(

    awful.key({ altkey, "shift"   }, "m",      lain.util.magnify_client,
              {description = "magnify client", group = "client"}),

    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),

    awful.key({ modkey,   }, "d",  function (c) naughty.notify{ text = "I live!" } c:kill() end,
              {description = "close", group = "client"}),

    awful.key({ modkey, "control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),

    awful.key({ modkey, "control" }, "return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),

    awful.key({ modkey,           }, "o",      function (c) naughty.notify{ text = "I move!" } c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),

    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),

    awful.key({ modkey,           }, "n",
        function (c)
            -- the client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),

    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "maximize", group = "client"})
)--}}}

-- About teaching setup:
globalkeys = my_table.join(globalkeys,
  --   awful.key({ modkey,   }, "e",
  --       function ()
	 --    naughty.notify{ text = "I am working now..." }
	 --    -- inspired by https://awesomewm.org/doc/api/libraries/awful.spawn.html
	 --    -- https://awesomewm.org/doc/api/classes/screen.html#awful.screen.focused
	 --    -- local screen = awful.screen.focus(1)
	 --    awful.screen.focus(screen[1])
	 --    local tag = screen[1].tags[2]
	 --    if tag then
		-- -- awful.tag.viewonly(tag)
		-- tag:view_only()
		-- awful.spawn.with_shell("TeachingNow.lua")
		-- -- awful.spawn.with_shell("urxvt -e tty-clock -B -x -c")
		-- awful.spawn.with_shell("urxvt -e tmux a -dt h")
		-- -- client:move_to_screen(screen[3])
	 --    end
	 --    -- awful.screen.focus(screen[2])
	 --    -- local tag = screen[2].tags[2]
	 --    -- if tag then
		-- -- -- awful.tag.viewonly(tag2)
		-- -- tag:view_only()
	 --    -- end
  --       end,
  --       {description = "Set up teaching mode", group = "Personalized"})

    awful.key({ modkey,   }, "e",
        function ()
	    naughty.notify{ text = "Stop screenkey ..." }
	    -- inspired by https://awesomewm.org/doc/api/libraries/awful.spawn.html
	    -- https://awesomewm.org/doc/api/classes/screen.html#awful.screen.focused
	    -- local screen = awful.screen.focus(1)
	    awful.screen.focus(screen[1])
	    local tag = screen[1].tags[2]
	    if tag then
		-- awful.tag.viewonly(tag)
		tag:view_only()
		awful.spawn.with_shell("killscreenkey.sh a")
		-- awful.spawn.with_shell("urxvt -e tty-clock -B -x -c")
		-- awful.spawn.with_shell("urxvt -e tmux a -dt h")
		-- client:move_to_screen(screen[3])
	    end
	    -- awful.screen.focus(screen[2])
	    -- local tag = screen[2].tags[2]
	    -- if tag then
		-- -- awful.tag.viewonly(tag2)
		-- tag:view_only()
	    -- end
        end,
        {description = "Set up teaching mode", group = "Personalized"})

)


globalkeys = my_table.join(globalkeys,
  --   awful.key({ modkey,   }, "e",
  --       function ()
	 --    naughty.notify{ text = "I am working now..." }
	 --    -- inspired by https://awesomewm.org/doc/api/libraries/awful.spawn.html
	 --    -- https://awesomewm.org/doc/api/classes/screen.html#awful.screen.focused
	 --    -- local screen = awful.screen.focus(1)
	 --    awful.screen.focus(screen[1])
	 --    local tag = screen[1].tags[2]
	 --    if tag then
		-- -- awful.tag.viewonly(tag)
		-- tag:view_only()
		-- awful.spawn.with_shell("TeachingNow.lua")
		-- -- awful.spawn.with_shell("urxvt -e tty-clock -B -x -c")
		-- awful.spawn.with_shell("urxvt -e tmux a -dt h")
		-- -- client:move_to_screen(screen[3])
	 --    end
	 --    -- awful.screen.focus(screen[2])
	 --    -- local tag = screen[2].tags[2]
	 --    -- if tag then
		-- -- -- awful.tag.viewonly(tag2)
		-- -- tag:view_only()
	 --    -- end
  --       end,
  --       {description = "Set up teaching mode", group = "Personalized"})

    awful.key({ modkey,   }, "y",
        function ()
	    naughty.notify{ text = "Start screenkey ..." }
	    -- inspired by https://awesomewm.org/doc/api/libraries/awful.spawn.html
	    -- https://awesomewm.org/doc/api/classes/screen.html#awful.screen.focused
	    -- local screen = awful.screen.focus(1)
	    awful.screen.focus(screen[1])
	    local tag = screen[1].tags[2]
	    if tag then
		-- awful.tag.viewonly(tag)
		tag:view_only()
		awful.spawn.with_shell("screenkey --bg-color green --scr 1 ")
		-- awful.spawn.with_shell("urxvt -e tty-clock -B -x -c")
		-- awful.spawn.with_shell("urxvt -e tmux a -dt h")
		-- client:move_to_screen(screen[3])
	    end
	    -- awful.screen.focus(screen[2])
	    -- local tag = screen[2].tags[2]
	    -- if tag then
		-- -- awful.tag.viewonly(tag2)
		-- tag:view_only()
	    -- end
        end,
        {description = "Set up teaching mode", group = "Personalized"})

)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.{{{
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    -- Hack to only show tags 1 and 9 in the shortcut window (mod+s)
    local descr_view, descr_toggle, descr_move, descr_toggle_focus
    if i == 1 or i == 9 then
        descr_view = {description = "view tag #", group = "tag"}
        descr_toggle = {description = "toggle tag #", group = "tag"}
        descr_move = {description = "move focused client to tag #", group = "tag"}
        descr_toggle_focus = {description = "toggle focused client on tag #", group = "tag"}
    end
    globalkeys = my_table.join(globalkeys,

	-- the following is to change workspace simultaneously; Le Chen
	--https://superuser.com/questions/556877/simultaneously-switch-tags-as-one-screen-in-multi-monitor-setup
	-- awful.key({ modkey, "Control" }, "#" .. i + 9,
	--           function ()
	--                 for j = 1, screen.count() do
	--                     awful.tag.viewonly(tags[j][i])
	--                 end
	--           end),
	awful.key({ modkey, "Control" }, "#" .. i + 9,
	    function ()
        for screen = 1, screen.count() do
            local tag = awful.tag.gettags(screen)[i]
            if tag then
              awful.tag.viewonly(tag)
            end
        end
	    end
	),

    -- View tag only.
    awful.key({ modkey }, "#" .. i + 9,
        function ()
            local screen = awful.screen.focused()
            local tag = screen.tags[i]
            if tag then
               tag:view_only()
            end
        end,
        descr_view),

    -- Move all screens to the tag No. i
    awful.key({ modkey, "Shift" }, "#" .. i + 9,
              function ()
                  if client.focus then
                      local tag = client.focus.screen.tags[i]
                      if tag then
                          client.focus:move_to_tag(tag)
                      end
                 end
              end,
              descr_move),

        -- Move all screens to the right tag
        awful.key({ modkey, "Control" }, "Right",
                  function ()
		    --https://www.reddit.com/r/awesomewm/comments/7cfef6/how_to_move_client_to_the_next_tag_in_list_tag/
		    -- local t = client.focus and client.focus.first_tag or nil
		    local t = client.focus and client.focus.first_tag or nil
            if t == nil then
              -- naughty.notify({ title = "Achtung!", text = "Index null", timeout = 0 })
            return
		    end
		    -- get next tag (modulo 9 excluding 0 to wrap from 9 to 1)
		    local index = t.index
		    if index == 9 then
            index = 1
		    else
            index = index + 1
		    end
		    -- naughty.notify({ title = "Achtung!", text = "Moving to ... " .. index .. " !", timeout = 0 })
		    for screen = 1, screen.count() do
            local tag = awful.tag.gettags(screen)[index]
            if tag then
                awful.tag.viewonly(tag)
            end
		    end
                  end,
                  descr_move),

        -- Move all screens to the right tag
        awful.key({ modkey, "Control" }, "Left",
                  function ()
		    --https://www.reddit.com/r/awesomewm/comments/7cfef6/how_to_move_client_to_the_next_tag_in_list_tag/
		    local t = client.focus and client.focus.first_tag or nil
		    if t == nil then
			-- naughty.notify({ title = "Achtung!", text = "Index null", timeout = 0 })
			return
		    end
		    local index = t.index
		    -- naughty.notify({ title = "Achtung!", text = "Moving to ... " .. index .. " !", timeout = 0 })
		    if index == 1 then
			index = 9
		    else
		      index = index -1
		    end
		    -- get next tag (modulo 9 excluding 0 to wrap from 9 to 1)
		    for screen = 1, screen.count() do
			local tag = awful.tag.gettags(screen)[index]
			if tag then
			    awful.tag.viewonly(tag)
			end
		    end
                  end,
                  descr_move),

        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "a",
                  function ()
		      local t = awful.screen.focused().selected_tag.index
		      -- naughty.notify({ title = "Achtung!", text = "You're idling... with t =" .. t.. " !", timeout = 0 })
		      for i=1,9,1 do
			  if i ~= t then
			      if client.focus then
				  local tag = client.focus.screen.tags[i]
				  if tag then
				      client.focus:toggle_tag(tag)
				  end
			      end
			  end
                      end
                  end,
                  descr_toggle_focus),

        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  descr_toggle_focus)
    )
end
--}}}

-- Finally, gears.table.join{{
clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)
--}}}

-- Set keys
root.keys(globalkeys)

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
myReadingMonitor = 1
if screen.count() > 1 then
  myReadingMonitor = 2
end

awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     -- Always-on-top window, Step 3-2: define rule
                     -- focus = custom_focus_filter,
                     -- Failed
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen,
                     size_hints_honor = false
     }
    },

    -- Titlebars
    { rule_any = { type = { "dialog", "normal" } },
      properties = { titlebars_enabled = false} },

    -- Set Firefox to always map on the first tag on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 2, tag = awful.util.tagnames[1] } },

    { rule = { class = "Firefox" },
      properties = {
        screen = myReadingMonitor,
        tag = awful.util.tagnames[7]
      } },

    { rule = { class = "mpv" },
      properties = {
        screen = myReadingMonitor
      } },

    -- Set Zoom to always map on the second tag on my reading monitor.
    { rule = { class = "zoom" },
      properties = {
        screen = myReadingMonitor,
        tag = awful.util.tagnames[2]
      } },

    -- Set Qutebrowser to always map on the second tag on my reading monitor.
    { rule = { class = "qutebrowser" },
      properties = { screen = myReadingMonitor } },

    -- Set sent to always map on the second tag on my reading monitor.
    { rule = { class = "sent" },
      properties = { screen = myReadingMonitor } },

    -- Set Qutebrowser to always map on the second tag on my reading monitor.
    { rule = { class = "vlc" },
      properties = { screen = myReadingMonitor } },

    -- Set Zathura to always map on the second tag on my reading monitor.
    { rule = { class = "Zathura" },
      properties = { screen = myReadingMonitor } },

    -- Set sxiv to always map on the second tag on my reading monitor.
    { rule = { class = "Sxiv" },
      properties = { screen = myReadingMonitor } },

    -- Set ChatGP to always map on the second tag on my reading monitor.
    { rule = { class = "chatgpt" },
      properties = {
        screen = myreadingdisplay,
        tag = awful.util.tagnames[3],
        maximized = true
      } },

    -- -- Set TeachingNow.lua to always map on the second tag on screen 1.
    -- Not successful
    -- { rule = { instance = "/home/lechen/bin/TeachingNow.lua" },
    --   properties = { screen = 1, tag = awful.util.tagnames[2] } },

    { rule = { class = "Gimp", role = "gimp-image-window" },
          properties = { maximized = true } }
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)
-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- Custom
    if beautiful.titlebar_fun then
        beautiful.titlebar_fun(c)
        return
    end

    -- Default
    -- buttons for the titlebar
    local buttons = my_table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 2, function() c:kill() end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c, {size = dpi(16)}) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal(),
            battery_widget()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {raise = vi_focus})
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- possible workaround for tag preservation when switching back to default screen:
-- https://github.com/lcpz/awesome-copycats/issues/251
-- }}}


