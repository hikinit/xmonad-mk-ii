import XMonad
import System.IO
import System.Exit

import Text.Printf

import XMonad.Actions.CycleWS
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.Place
import XMonad.Layout
import XMonad.Layout.Gaps
import XMonad.Layout.PerWorkspace
import XMonad.Layout.Renamed
import XMonad.Layout.Spacing
import XMonad.Layout.Tabbed
import XMonad.Layout.TwoPane
import XMonad.Util.EZConfig
import XMonad.Util.Run
import XMonad.Util.SpawnOnce

import qualified XMonad.StackSet as W

-- Variables
terminal' = "kitty"
browser = "google-chrome-stable"
modifier = mod4Mask
mouseFollow = False

screenWidth = 1920
barSize = 24

menuBarWidth = round screenWidth
menuBarOffset = 0

bottomBarConfig = "$HOME/.xmonad/bottom.conf"
statusBarConfig = "$HOME/.xmonad/status.conf"

statusBarWidth = round $ screenWidth * 0.3
statusBarOffset = round $ screenWidth * 0.7

--- Styles
screenGaps = 30
windowGaps = 10
borderWidth' = 0
barColor = "#005199cb"
barColor' = "#5199cb"
barLayoutColor = "#BB8784"

textFont = "-xos4-terminus-medium-r-normal--14-140-72-72-c-80-iso10646-1"
iconFont = "-wuncon-siji-medium-r-normal--0-0-75-75-c-0-iso10646-1"
japFont = "PixelMplus12:size=9"

-- Workspace
workspaceList =
  [ "\xe1ec HOME"
  , "\xe26d WEB"
  , "\xe1d8 DEV"
  , "\xe1a7 COM"
  , "\xe19d ENT" ]

workspaces' = do
  (i, ws) <- zip [1 ..] workspaceList
  [ "%{A:xdotool key super+"++ show i ++":}" ++ ws ++ "%{A}" ]

-- Shortcut
restartXmonad = "xmonad --recompile && xmonad --restart"
keyboardShortcuts =
  [ ("M-p", spawn "rofi -show run")
  , ("M-b", spawn browser)
  -- Xmonad
  , ("M-S-j", nextWS)
  , ("M-S-k", prevWS)
  , ("M-`", toggleWS)
  , ("M-S-x q", io exitSuccess)
  , ("M-S-x r", spawn restartXmonad)
  , ("M-q", kill)
  -- Media
  , ("M-<F12>", spawn "playerctl play-pause")
  , ("M-<Up>", spawn "xbacklight -inc 1")
  , ("M-<Down>", spawn "xbacklight -dec 1")
  , ("M-<Left>", spawn "pulsemixer --change-volume -5 --max-volume 90")
  , ("M-<Right>", spawn "pulsemixer --change-volume +5 --max-volume 90")
  -- Screenshot
  , ("<Print>", spawn "flameshot full -c")
  , ("S-<Print>", spawn "flameshot gui") ]

removeKeyboardShortcuts =
  [ "M-S-q", "M-q" -- quit and reload xmonad
  , "M-S-c" -- kill window
  , "M-S-p" -- dmenu gmrun
  , "M-<Tab>", "M-S-<Tab>" -- switch window
  , "M-S-j", "M-S-k" -- swap window order
  , "M-,", "M-." -- resize master count
  , "M-S-w", "M-S-e", "M-S-r" -- swap screen
  , "M-w", "M-e", "M-r" -- move screen
  ]

mouseBindings' =
  [ ((mod4Mask, button4), \w -> windows W.focusUp)
  , ((mod4Mask, button5), \w -> windows W.focusDown)
  , ((mod4Mask .|. shiftMask, button4), \w -> prevWS)
  , ((mod4Mask .|. shiftMask, button5), \w -> nextWS) ]


-- Layout
myTabConfig = def
  { fontName = "xft: Terminus (TTF):size=9"
  , inactiveColor = barColor'
  , inactiveBorderWidth = 0
  , inactiveTextColor = "#ffffff"
  , activeColor = barLayoutColor
  , activeBorderWidth = 0
  , activeTextColor = "#ffffff" }

tabLayout = tabbed shrinkText myTabConfig

layoutHook' = avoidStruts
  $ renamed [CutWordsLeft 1]
  $ gaps [(L,screenGaps), (U,screenGaps), (R,screenGaps), (D,gapWithBar)]
  $ spacingRaw True
    (Border 0 0 0 0) True
    (Border windowGaps windowGaps windowGaps windowGaps) True
  $ onWorkspace (w !! 1) webLayout
  $ onWorkspace (w !! 2) webLayout
  $ onWorkspace (w !! 3) comLayout
  $ onWorkspace (w !! 4) comLayout
  $ layoutHook defaultConfig
  where
    w = workspaces'
    gapWithBar = screenGaps `div` 2
    webLayout = tabLayout ||| TwoPane (3/100) (1/2)
    comLayout = tabLayout

-- Manage hook
devApps = ["code-oss", "Code"]
comApps = ["Slack", "discord"]
entApps = ["steam_proton", "Steam", "Qemu-system-x86_64"]
floatingApps =
  [ "Nvidia-settings"
  , "pritunl"
  , "Nm-connection-editor"
  , "Snapper-gui" ]

myHook = composeAll $ concat $
  [ [ isBrowser --> doShift (w !! 1) ]
  , [ className =? c --> doShift (w !! 2) | c <- devApps ]
  , [ className =? c --> doShift (w !! 3) | c <- comApps ]
  , [ className =? c --> doShift (w !! 4) | c <- entApps ]
  , [ className =? c --> doFloat | c <- floatingApps ]
  , [ isFullscreen --> doFullFloat ]
  , [ isDialog --> doFloat ]
  , [ isPopUp --> doFloat ]
  ] where
    w = workspaces'
    isBrowser = stringProperty "WM_WINDOW_ROLE" =? "browser"
    isPopUp = stringProperty "WM_WINDOW_ROLE" =? "pop-up"

manageHook' =
  placeHook (smart (0.5,0.5))
  <+> myHook
  <+> manageDocks
  <+> manageHook def

-- Startup
startupHook' = do
  spawnOnce "feh --no-fehbg --bg-fill $HOME/.xmonad/background.jpg"
  spawnOnce "xsetroot -cursor_name left_ptr"
  spawnOnce "picom"
  spawnOnce "redshift"
  spawnOnce "nm-applet"
  spawnOnce "dunst"
  spawnOnce "setxkbmap -option altwin:swap_alt_win"

-- Menubar
lemonbar width offsetX offsetY = printf
  "lemonbar -n bar -d -g %sx%s+%s+%s -B '%s' -f %s -f %s -f %s %s | sh"
  (show width)
  (show barSize)
  (show offsetX)
  (show offsetY)
  barColor
  textFont
  iconFont
  japFont

menuBar = lemonbar menuBarWidth menuBarOffset 0 ""
statusBar' = "pkill conky; conky -c "
  ++ statusBarConfig ++ " | "
  ++ lemonbar statusBarWidth statusBarOffset 0 ""

bottomBar = "pkill conky; conky -c "
  ++ bottomBarConfig ++ " | "
  ++ lemonbar (menuBarWidth `div` 2) menuBarOffset 4 "-b"

trayBar = printf "pkill stalonetray; stalonetray -t -i 20 --geometry 5x1-%s-%s \
  \ --window-type dock \
  \ --window-strut bottom \
  \ --kludges force_icons_size \
  \ --grow-gravity NE \
  \ --icon-gravity NE"
  (show screenGaps)
  (show 4)

logHook' h = dynamicLogWithPP
  $ def
    { ppOutput = hPutStrLn h
    , ppOrder = \(w:l:t:_) -> [l,w,t]
    , ppSep = ""
    , ppWsSep = ""
    , ppTitle = wrap "%{c}" "%{l}" . shorten 90
    , ppCurrent = wrap "%{R}" "%{R}" . pad . pad
    , ppHidden  = pad . pad
    , ppLayout = wrap ("%{B" ++ barLayoutColor ++"}") "%{B-}" . pad .
      (\l -> case l of
        "Tall" -> "\xe002"
        "Mirror Tall" -> "\xe003"
        "Full" -> "\xe000"
        "TwoPane" -> "\xe26b"
        "Tabbed Simplest" -> "\xe135"
        _ -> l
      )
    }

eventHook' = docksEventHook
  <+> ewmhDesktopsEventHook
  <+> fullscreenEventHook

-- Main
main = do
  menuBar <- spawnPipe menuBar
  spawn statusBar'
  spawn bottomBar
  spawn trayBar
  xmonad
    $ docks
    $ ewmh
    $ defaultConfig
      { terminal = terminal'
      , modMask = modifier
      , borderWidth = borderWidth'
      , focusFollowsMouse = mouseFollow
      , workspaces = workspaces'
      , handleEventHook = eventHook'
      , layoutHook = layoutHook'
      , logHook = logHook' menuBar
      , manageHook = manageHook'
      , startupHook = startupHook'
      }
    `removeKeysP` removeKeyboardShortcuts
    `additionalKeysP` keyboardShortcuts
    `additionalMouseBindings` mouseBindings'
