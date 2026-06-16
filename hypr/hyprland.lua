-- Converted from hyprland.conf to Hyprland 0.55+ Lua config.
-- Put this file at: ~/.config/hypr/hyprland.lua
-- Your old hyprland.conf can be kept as a backup while testing.

------------------
---- MONITORS ----
------------------

hl.monitor({
  output = "eDP-1",
  mode = "1366x768@60.06900",
  position = "0x0",
  scale = 1,
})

---------------------
---- MY PROGRAMS ----
---------------------

local terminal = "foot"
local fileManager = "dolphin"
local menu = "wofi --show drun"

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
  hl.exec_cmd("fcitx5 -d")
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("awww img ~/Pictures/main/frieren-3.jpg --transition-type any")
  hl.exec_cmd("wal -a \"85\" -i ~/Pictures/main/frieren-3.jpg")
  hl.exec_cmd("quickshell")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GTK_IM_MODULE", "fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")

-----------------------
---- LOOK AND FEEL ----
-----------------------

local function quickshell_borders()
  local path = os.getenv("HOME") .. "/.config/quickshell/generated/hyprland/borders.lua"
  local ok, borders = pcall(dofile, path)
  if ok and type(borders) == "table" then
    return borders
  end
  return {
    active_border = { colors = { "rgba(212,165,196,1)", "rgba(189,163,200,1)" }, angle = 50 },
    inactive_border = { colors = { "rgba(193,142,176,0.6)", "rgba(124,105,214,0.6)" }, angle = 50 },
  }
end

local shell_borders = quickshell_borders()

hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 18,
    border_size = 2,
    col = {
      active_border = shell_borders.active_border,
      inactive_border = shell_borders.inactive_border,
    },
    resize_on_border = false,
    allow_tearing = false,
    layout = "dwindle",
  },

  decoration = {
    rounding = 2,
    rounding_power = 2,
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    shadow = {
      enabled = true,
      range = 4,
      render_power = 3,
      color = "rgba(1a1a1aee)",
    },
    blur = {
      enabled = true,
      size = 5,
      passes = 2,
      vibrancy = 0.1696,
      xray = false,
      new_optimizations = true,
    },
  },

  animations = {
    enabled = true,
  },
})

-- Discord
hl.window_rule({
  name = "discord_rules",
  match = { class = "^(discord)$" },
  float = true,
  workspace = "5",
})

-- Telegram
hl.window_rule({
  name = "telegram_rules",
  match = { class = "^(org.telegram.desktop)$" },
  float = true,
  workspace = "5",
})

-- Quickshell windows with custom QML open/close animations. These should not
-- also get Hyprland layer animations.
hl.layer_rule({
  name = "quickshell_applauncher_no_anim",
  match = { namespace = "quickshell:applauncher" },
  no_anim = true,
})

hl.layer_rule({
  name = "quickshell_dashboard_no_anim",
  match = { namespace = "quickshell:dashboard" },
  no_anim = true,
})

hl.layer_rule({
  name = "quickshell_bar_panel_no_anim",
  match = { namespace = "quickshell:bar-panel" },
  no_anim = true,
})

hl.layer_rule({
  name = "quickshell_system_monitor_no_anim",
  match = { namespace = "quickshell:system-monitor" },
  no_anim = true,
})

hl.window_rule({
  name = "quickshell_no_window_anim",
  match = { class = "^(quickshell|qs)$" },
  no_anim = true,
})

-- Animations
hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.8 }, { 0.1, 1 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 6, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 90%" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 8, bezier = "default", style = "slide" })

-- Layouts
hl.config({
  dwindle = {
    force_split = 0,
    preserve_split = true,
  },
  master = {
    new_status = "master",
  },
  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo = true,
  },
})

---------------
---- INPUT ----
---------------

hl.config({
  input = {
    kb_layout = "us, ru",
    kb_variant = "",
    kb_model = "",
    kb_options = "grp:alt_shift_toggle",
    kb_rules = "",
    follow_mouse = 1,
    sensitivity = 0,
    touchpad = {
      natural_scroll = false,
    },
  },
})

hl.device({
  name = "epic-mouse-v1",
  sensitivity = -0.5,
})

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

-- Quickshell
hl.bind(mainMod .. " + A", hl.dsp.global("quickshell:applauncherToggle"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("qs ipc call lock activate"))
hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("quickshell ipc call systemMonitor toggle"))
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("qs ipc call dashboard toggle"))
hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd("qs ipc call barPanel toggle"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("qs ipc call settings toggle"))

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
-- hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd("flatpak run app.zen_browser.zen"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("Telegram"))
hl.bind(mainMod .. " + Insert", hl.dsp.exec_cmd("quickshell ipc call screenshot open"))
hl.bind(mainMod .. " + SHIFT + Insert", hl.dsp.exec_cmd("quickshell ipc call screenshot open"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Resize active window
hl.bind("SUPER + CTRL + right", hl.dsp.window.resize({ x = 40, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + CTRL + left", hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + CTRL + up", hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true })
hl.bind("SUPER + CTRL + down", hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { repeating = true })

-- Move active window
hl.bind("SUPER + SHIFT + Left", hl.dsp.window.move({ direction = "l" }))
hl.bind("SUPER + SHIFT + Right", hl.dsp.window.move({ direction = "r" }))
hl.bind("SUPER + SHIFT + Up", hl.dsp.window.move({ direction = "u" }))
hl.bind("SUPER + SHIFT + Down", hl.dsp.window.move({ direction = "d" }))

-- Switch workspaces / move active window to workspace
for i = 1, 10 do
  local key = i % 10 -- workspace 10 is bound to key 0
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace / scratchpad
--hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
--hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

---------------
---- GESTURES ----
---------------

hl.gesture({
  fingers = 3,
  direction = "horizontal",
  action = "workspace",
})

hl.gesture({
  fingers = 3,
  direction = "vertical",
  action = "special",
  argument = "magic",
})

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Optional old rules from the generated config, left disabled:
-- hl.window_rule({
--   name = "suppress-maximize-events",
--   match = { class = ".*" },
--   suppress_event = "maximize",
-- })
-- hl.window_rule({
--   name = "fix-xwayland-drags",
--   match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
--   no_focus = true,
-- })
