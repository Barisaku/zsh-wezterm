local wezterm = require("wezterm")

-- WezTerm の action を短く書くための別名。
local act = wezterm.action

-- SSH profile ごとの安全設定を参照する。
local ssh_profiles = require("ssh_profiles")

-- 右上ステータスに出す貼り付け警告状態。
local paste_notice = nil

-- 現在の workspace 名を変更する。
local function rename_workspace(_, _, line)
  -- 入力が空でなければ workspace 名として反映する。
  if line then
    wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
  end
end

-- 複数の clipboard 取得コマンドを順番に試し、最初に成功した結果を返す。
local function first_successful_command(commands)
  local empty_stdout = nil

  for _, command in ipairs(commands) do
    -- 外部コマンドを実行して clipboard 文字列を取得する。
    local ok, stdout = wezterm.run_child_process(command)

    -- 成功して中身があれば標準出力を clipboard 文字列として返す。
    if ok and stdout ~= nil and stdout ~= "" then
      return stdout
    end

    -- 成功したが空だった場合は、後続の fallback も試す。
    if ok and stdout == "" and empty_stdout == nil then
      empty_stdout = stdout
    end
  end

  -- clipboard が本当に空の場合に備え、空文字列を返す。
  return empty_stdout
end

-- OS ごとに clipboard 文字列を取得する。
local function get_clipboard_text()
  -- macOS は pbpaste を使う。
  if wezterm.target_triple:find("darwin") then
    return first_successful_command({ { "pbpaste" } })
  end

  -- Windows は win32yank.exe を優先し、無ければ PowerShell の Get-Clipboard に fallback する。
  -- PowerShell 起動は遅いため、install.sh --install-tools では win32yank.exe を導入する。
  if wezterm.target_triple:find("windows") then
    local win32yank_in_user_bin = wezterm.home_dir .. "\\bin\\win32yank.exe"

    return first_successful_command({
      { win32yank_in_user_bin, "-o", "--lf" },
      { "win32yank.exe", "-o", "--lf" },
      { "powershell.exe", "-NoProfile", "-Command", "[Console]::Out.Write((Get-Clipboard -Raw))" },
    })
  end

  -- Linux は Wayland / X11 の代表的な clipboard コマンドを順番に試す。
  return first_successful_command({
    { "wl-paste", "--no-newline" },
    { "xclip", "-selection", "clipboard", "-out" },
    { "xsel", "--clipboard", "--output" },
  })
end

-- clipboard 文字列を terminal に流しやすい形へ整える。
-- Windows の CRLF はそのまま送ると行間に空行ができることがあるため LF に揃える。
-- 末尾改行は、単語だけの paste で Enter 扱いにならないよう取り除く。
local function normalize_clipboard_text(text)
  if text == nil then
    return nil
  end

  text = text:gsub("\r\n", "\n")
  text = text:gsub("\r", "\n")
  text = text:gsub("\n+$", "")

  return text
end

-- 正規化済み文字列を pane へ貼り付ける。
-- OS ごとの clipboard を書き換えず、WezTerm の paste 経路で送る。
local function paste_normalized_text(_, pane, text)
  pane:send_paste(text)
end

-- 文字列が複数行かどうかを判定する。
local function is_multiline(text)
  if text == nil then
    return false
  end

  -- LF または CR が含まれていれば複数行扱いにする。
  return text:find("\n") ~= nil or text:find("\r") ~= nil
end

-- 文字列の行数を数える。
local function count_lines(text)
  -- 1 行以上ある前提で数え始める。
  local count = 1

  -- 空文字列は 0 行扱いにする。
  if text == nil or text == "" then
    return 0
  end

  -- 改行数 + 1 を行数として数える。
  for _ in text:gmatch("\n") do
    count = count + 1
  end

  return count
end

-- 複数行ペースト確認に出す短い preview を作る。
local function preview_text(text, max_lines)
  -- preview に含める行を入れる配列。
  local lines = {}

  -- 何行入れたかを数える。
  local count = 0

  -- 最大 max_lines 行まで先頭から取り出す。
  for line in text:gmatch("([^\n]*)\n?") do
    -- gmatch の末尾空行を余分に入れない。
    if line == "" and count > 0 then
      break
    end

    count = count + 1
    table.insert(lines, line)

    if count >= max_lines then
      break
    end
  end

  -- 1 行表示に収めるため、各行を / でつなぐ。
  return table.concat(lines, " / ")
end

-- pane を識別するための ID を安全に取得する。
local function pane_identity(pane)
  local ok, pane_id = pcall(function()
    return pane:pane_id()
  end)

  if ok and pane_id ~= nil then
    return tostring(pane_id)
  end

  return tostring(pane)
end

-- ローカル側で警告音を鳴らす。
-- BEL を pane へ送ると remote shell/Vim に Ctrl-g として届き得るため、
-- OS 側の短い通知音を background process で鳴らす。
local function ring_local_bell()
  local command = nil

  if wezterm.target_triple:find("darwin") then
    command = { "osascript", "-e", "beep" }
  elseif wezterm.target_triple:find("windows") then
    command = { "powershell.exe", "-NoProfile", "-Command", "[console]::beep(880,120)" }
  else
    command = { "sh", "-lc", "command -v canberra-gtk-play >/dev/null 2>&1 && canberra-gtk-play -i bell >/dev/null 2>&1" }
  end

  pcall(function()
    wezterm.background_child_process(command)
  end)
end

-- 貼り付け警告を右上ステータスに出す。
local function set_paste_notice(window, pane, kind, message, seconds)
  paste_notice = {
    pane_id = pane_identity(pane),
    kind = kind,
    message = message,
    expires_at = os.time() + seconds,
  }

  -- update-right-status を待たず、なるべく即時に右上表示を更新する。
  window:perform_action(act.EmitEvent("refresh-status"), pane)
  -- 視覚警告だけだと見落とすため、ローカル通知音も鳴らす。
  ring_local_bell()
end

-- 貼り付け警告を消す。
local function clear_paste_notice(window, pane)
  paste_notice = nil
  window:perform_action(act.EmitEvent("refresh-status"), pane)
end

-- wezterm.lua から呼ばれ、右上ステータスに貼り付け警告を追加する。
local function paste_status_cells(pane)
  if paste_notice == nil then
    return {}
  end

  if os.time() > paste_notice.expires_at then
    paste_notice = nil
    return {}
  end

  if paste_notice.pane_id ~= pane_identity(pane) then
    return {}
  end

  local bg = "#b7791f"
  local fg = "#101010"

  if paste_notice.kind == "prod" then
    bg = "#c53030"
    fg = "#ffffff"
  end

  return {
    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    { Attribute = { Intensity = "Bold" } },
    { Text = " " .. paste_notice.message .. " " },
    { Attribute = { Intensity = "Normal" } },
  }
end

-- 複数行ペーストの確認 UI を開く。
local function prompt_multiline_paste(window, pane, text, kind, line_count, preview)
  -- prod は特に目立つ文言にする。
  local description = "Multiline paste: " .. tostring(line_count) .. " lines. Enter to paste, Esc to cancel."

  if kind == "prod" then
    description = "PROD multiline paste: " .. tostring(line_count) .. " lines. Enter to paste, Esc to cancel."
  end

  -- 右上警告と通知音を先に出してから、WezTerm の確認 UI を開く。
  if kind == "prod" then
    set_paste_notice(window, pane, "prod", "PROD PASTE: " .. tostring(line_count) .. " lines", 30)
  else
    set_paste_notice(window, pane, "confirm", "MULTILINE PASTE: " .. tostring(line_count) .. " lines", 30)
  end

  window:toast_notification("WezTerm", description .. " / " .. preview, nil, 5000)
  window:perform_action(
    act.PromptInputLine({
      description = description,
      action = wezterm.action_callback(function(confirm_window, confirm_pane, line)
        clear_paste_notice(confirm_window, confirm_pane)

        -- Esc でキャンセルされた場合は nil になる。
        if line ~= nil then
          paste_normalized_text(confirm_window, confirm_pane, text)
        end
      end),
    }),
    pane
  )
end

-- 安全ペースト。単一行はそのまま、複数行は確認 UI を出してから貼り付ける。
local function safe_paste(window, pane)
  clear_paste_notice(window, pane)

  -- clipboard の中身を取得する。
  local text = normalize_clipboard_text(get_clipboard_text())

  -- clipboard が空なら何もしない。
  if text == nil or text == "" then
    return
  end

  -- 単一行なら通常通り貼り付ける。
  if not is_multiline(text) then
    paste_normalized_text(window, pane, text)
    return
  end

  -- 確認メッセージに表示する行数。
  local line_count = count_lines(text)

  -- 確認メッセージに表示する先頭 preview。
  local preview = preview_text(text, 3)

  -- prod では強い警告色で確認 UI を出す。
  if ssh_profiles.blocks_multiline_paste(pane) then
    prompt_multiline_paste(window, pane, text, "prod", line_count, preview)
    return
  end

  -- 通常環境でも確認 UI を出す。
  prompt_multiline_paste(window, pane, text, "confirm", line_count, preview)
end

-- Ctrl-c 用の smart copy。
-- 選択範囲がある時だけコピーし、選択がない時は通常の Ctrl-c を shell へ渡す。
local function smart_copy_or_interrupt(window, pane)
  local ok, selection = pcall(function()
    return window:get_selection_text_for_pane(pane)
  end)

  if ok and selection ~= nil and selection ~= "" then
    window:perform_action(act.CopyTo("Clipboard"), pane)
    window:perform_action(act.ClearSelection, pane)
    return
  end

  window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
end

local M = {
  -- 通常時のキーバインド。
  keys = {
    {
      -- Ctrl-q w: workspace 一覧を表示する。
      key = "w",
      mods = "LEADER",
      action = act.ShowLauncherArgs({ flags = "WORKSPACES", title = "Select workspace" }),
    },
    {
      -- Ctrl-q $: 現在の workspace 名を変更する。
      key = "$",
      mods = "LEADER",
      action = act.PromptInputLine({
        description = "(wezterm) Set workspace title:",
        action = wezterm.action_callback(rename_workspace),
      }),
    },
    {
      -- Ctrl-q Shift-W: 新しい workspace を作って切り替える。
      key = "W",
      mods = "LEADER|SHIFT",
      action = act.PromptInputLine({
        description = "(wezterm) Create new workspace:",
        action = wezterm.action_callback(function(window, pane, line)
          -- 入力された名前があれば、その workspace に切り替える。
          if line then
            window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
          end
        end),
      }),
    },
    {
      -- Ctrl-q Shift-S: launch menu を表示する。SSH 接続先もここに出る。
      key = "S",
      mods = "LEADER|SHIFT",
      action = act.ShowLauncherArgs({ flags = "LAUNCH_MENU_ITEMS" }),
    },
    {
      -- Cmd-p: コマンドパレットを開く。
      key = "p",
      mods = "SUPER",
      action = act.ActivateCommandPalette,
    },
    {
      -- Ctrl-Tab: 次のタブへ移動する。
      key = "Tab",
      mods = "CTRL",
      action = act.ActivateTabRelative(1),
    },
    {
      -- Ctrl-Shift-Tab: 前のタブへ移動する。
      key = "Tab",
      mods = "SHIFT|CTRL",
      action = act.ActivateTabRelative(-1),
    },
    {
      -- Ctrl-q {: タブを左へ移動する。
      key = "{",
      mods = "LEADER",
      action = act({ MoveTabRelative = -1 }),
    },
    {
      -- Ctrl-q }: タブを右へ移動する。
      key = "}",
      mods = "LEADER",
      action = act({ MoveTabRelative = 1 }),
    },
    {
      -- Cmd-t: 現在と同じ domain で新しいタブを作る。
      key = "t",
      mods = "SUPER",
      action = act({ SpawnTab = "CurrentPaneDomain" }),
    },
    {
      -- Windows/Linux 用 Ctrl-Shift-t: 現在と同じ domain で新しいタブを作る。
      key = "t",
      mods = "CTRL|SHIFT",
      action = act({ SpawnTab = "CurrentPaneDomain" }),
    },
    {
      -- Windows 用 Ctrl-t: Caps Lock=Ctrl 運用で新しいタブを作る。
      key = "t",
      mods = "CTRL",
      action = act({ SpawnTab = "CurrentPaneDomain" }),
    },
    {
      -- Windows/Linux 用 Alt-t: Cmd-t 相当。英字キーボードの Cmd 位置に寄せる。
      key = "t",
      mods = "ALT",
      action = act({ SpawnTab = "CurrentPaneDomain" }),
    },
    {
      -- Cmd-w: 現在のタブを確認付きで閉じる。
      key = "w",
      mods = "SUPER",
      action = act({ CloseCurrentTab = { confirm = true } }),
    },
    {
      -- Windows/Linux 用 Ctrl-Shift-w: 現在のタブを確認付きで閉じる。
      key = "w",
      mods = "CTRL|SHIFT",
      action = act({ CloseCurrentTab = { confirm = true } }),
    },
    {
      -- Windows/Linux 用 Alt-w: Cmd-w 相当。英字キーボードの Cmd 位置に寄せる。
      key = "w",
      mods = "ALT",
      action = act({ CloseCurrentTab = { confirm = true } }),
    },
    {
      -- Alt-Enter: フルスクリーンを切り替える。
      key = "Enter",
      mods = "ALT",
      action = act.ToggleFullScreen,
    },
    {
      -- Ctrl-q [: copy mode に入る。
      key = "[",
      mods = "LEADER",
      action = act.ActivateCopyMode,
    },
    {
      -- Cmd-c: 選択範囲を clipboard へコピーする。
      key = "c",
      mods = "SUPER",
      action = act.CopyTo("Clipboard"),
    },
    {
      -- Windows 用 Ctrl-c: 選択範囲ありならコピー、なしなら shell へ中断を送る。
      key = "c",
      mods = "CTRL",
      action = wezterm.action_callback(smart_copy_or_interrupt),
    },
    {
      -- Windows/Linux 用 Ctrl-Shift-c: 選択範囲を clipboard へコピーする。
      key = "c",
      mods = "CTRL|SHIFT",
      action = act.CopyTo("Clipboard"),
    },
    {
      -- Windows/Linux 用 Alt-c: Cmd-c 相当。選択範囲を clipboard へコピーする。
      key = "c",
      mods = "ALT",
      action = act.CopyTo("Clipboard"),
    },
    {
      -- Cmd-v: 安全ペーストを実行する。
      key = "v",
      mods = "SUPER",
      action = wezterm.action_callback(safe_paste),
    },
    {
      -- Windows 用 Ctrl-v: Caps Lock=Ctrl 運用で安全ペーストを実行する。
      key = "v",
      mods = "CTRL",
      action = wezterm.action_callback(safe_paste),
    },
    {
      -- Ctrl-Shift-V: 安全ペーストを実行する。
      key = "v",
      mods = "CTRL|SHIFT",
      action = wezterm.action_callback(safe_paste),
    },
    {
      -- Windows/Linux 用 Alt-v: Cmd-v 相当。安全ペーストを実行する。
      key = "v",
      mods = "ALT",
      action = wezterm.action_callback(safe_paste),
    },
    {
      -- Ctrl-q d: pane を上下に分割する。
      key = "d",
      mods = "LEADER",
      action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
    },
    {
      -- Ctrl-q r: pane を左右に分割する。
      key = "r",
      mods = "LEADER",
      action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
    },
    {
      -- Ctrl-q x: 現在の pane を確認付きで閉じる。
      key = "x",
      mods = "LEADER",
      action = act({ CloseCurrentPane = { confirm = true } }),
    },
    {
      -- Ctrl-q h: 左の pane へ移動する。
      key = "h",
      mods = "LEADER",
      action = act.ActivatePaneDirection("Left"),
    },
    {
      -- Ctrl-q l: 右の pane へ移動する。
      key = "l",
      mods = "LEADER",
      action = act.ActivatePaneDirection("Right"),
    },
    {
      -- Ctrl-q k: 上の pane へ移動する。
      key = "k",
      mods = "LEADER",
      action = act.ActivatePaneDirection("Up"),
    },
    {
      -- Ctrl-q j: 下の pane へ移動する。
      key = "j",
      mods = "LEADER",
      action = act.ActivatePaneDirection("Down"),
    },
    {
      -- Ctrl-Shift-[: pane 選択 UI を表示する。
      key = "[",
      mods = "CTRL|SHIFT",
      action = act.PaneSelect,
    },
    {
      -- Windows/Linux 用 Alt-[: pane 選択 UI を表示する。
      key = "[",
      mods = "ALT",
      action = act.PaneSelect,
    },
    {
      -- Ctrl-q z: 現在 pane の zoom 表示を切り替える。
      key = "z",
      mods = "LEADER",
      action = act.TogglePaneZoomState,
    },
    {
      -- Ctrl-+: フォントサイズを大きくする。
      key = "+",
      mods = "CTRL",
      action = act.IncreaseFontSize,
    },
    {
      -- Ctrl--: フォントサイズを小さくする。
      key = "-",
      mods = "CTRL",
      action = act.DecreaseFontSize,
    },
    {
      -- Ctrl-0: フォントサイズを初期値に戻す。
      key = "0",
      mods = "CTRL",
      action = act.ResetFontSize,
    },
    {
      -- Cmd-1: 1 番目のタブへ移動する。
      key = "1",
      mods = "SUPER",
      action = act.ActivateTab(0),
    },
    {
      -- Windows/Linux 用 Alt-1: 1 番目のタブへ移動する。
      key = "1",
      mods = "ALT",
      action = act.ActivateTab(0),
    },
    {
      -- Windows 用 Ctrl-1: Caps Lock=Ctrl 運用で 1 番目のタブへ移動する。
      key = "1",
      mods = "CTRL",
      action = act.ActivateTab(0),
    },
    {
      -- Cmd-2: 2 番目のタブへ移動する。
      key = "2",
      mods = "SUPER",
      action = act.ActivateTab(1),
    },
    {
      -- Windows/Linux 用 Alt-2: 2 番目のタブへ移動する。
      key = "2",
      mods = "ALT",
      action = act.ActivateTab(1),
    },
    {
      -- Windows 用 Ctrl-2: Caps Lock=Ctrl 運用で 2 番目のタブへ移動する。
      key = "2",
      mods = "CTRL",
      action = act.ActivateTab(1),
    },
    {
      -- Cmd-3: 3 番目のタブへ移動する。
      key = "3",
      mods = "SUPER",
      action = act.ActivateTab(2),
    },
    {
      -- Windows/Linux 用 Alt-3: 3 番目のタブへ移動する。
      key = "3",
      mods = "ALT",
      action = act.ActivateTab(2),
    },
    {
      -- Windows 用 Ctrl-3: Caps Lock=Ctrl 運用で 3 番目のタブへ移動する。
      key = "3",
      mods = "CTRL",
      action = act.ActivateTab(2),
    },
    {
      -- Cmd-4: 4 番目のタブへ移動する。
      key = "4",
      mods = "SUPER",
      action = act.ActivateTab(3),
    },
    {
      -- Windows/Linux 用 Alt-4: 4 番目のタブへ移動する。
      key = "4",
      mods = "ALT",
      action = act.ActivateTab(3),
    },
    {
      -- Windows 用 Ctrl-4: Caps Lock=Ctrl 運用で 4 番目のタブへ移動する。
      key = "4",
      mods = "CTRL",
      action = act.ActivateTab(3),
    },
    {
      -- Cmd-5: 5 番目のタブへ移動する。
      key = "5",
      mods = "SUPER",
      action = act.ActivateTab(4),
    },
    {
      -- Windows/Linux 用 Alt-5: 5 番目のタブへ移動する。
      key = "5",
      mods = "ALT",
      action = act.ActivateTab(4),
    },
    {
      -- Windows 用 Ctrl-5: Caps Lock=Ctrl 運用で 5 番目のタブへ移動する。
      key = "5",
      mods = "CTRL",
      action = act.ActivateTab(4),
    },
    {
      -- Cmd-6: 6 番目のタブへ移動する。
      key = "6",
      mods = "SUPER",
      action = act.ActivateTab(5),
    },
    {
      -- Windows/Linux 用 Alt-6: 6 番目のタブへ移動する。
      key = "6",
      mods = "ALT",
      action = act.ActivateTab(5),
    },
    {
      -- Windows 用 Ctrl-6: Caps Lock=Ctrl 運用で 6 番目のタブへ移動する。
      key = "6",
      mods = "CTRL",
      action = act.ActivateTab(5),
    },
    {
      -- Cmd-7: 7 番目のタブへ移動する。
      key = "7",
      mods = "SUPER",
      action = act.ActivateTab(6),
    },
    {
      -- Windows/Linux 用 Alt-7: 7 番目のタブへ移動する。
      key = "7",
      mods = "ALT",
      action = act.ActivateTab(6),
    },
    {
      -- Windows 用 Ctrl-7: Caps Lock=Ctrl 運用で 7 番目のタブへ移動する。
      key = "7",
      mods = "CTRL",
      action = act.ActivateTab(6),
    },
    {
      -- Cmd-8: 8 番目のタブへ移動する。
      key = "8",
      mods = "SUPER",
      action = act.ActivateTab(7),
    },
    {
      -- Windows/Linux 用 Alt-8: 8 番目のタブへ移動する。
      key = "8",
      mods = "ALT",
      action = act.ActivateTab(7),
    },
    {
      -- Windows 用 Ctrl-8: Caps Lock=Ctrl 運用で 8 番目のタブへ移動する。
      key = "8",
      mods = "CTRL",
      action = act.ActivateTab(7),
    },
    {
      -- Cmd-9: 最後のタブへ移動する。
      key = "9",
      mods = "SUPER",
      action = act.ActivateTab(-1),
    },
    {
      -- Windows/Linux 用 Alt-9: 最後のタブへ移動する。
      key = "9",
      mods = "ALT",
      action = act.ActivateTab(-1),
    },
    {
      -- Windows 用 Ctrl-9: Caps Lock=Ctrl 運用で最後のタブへ移動する。
      key = "9",
      mods = "CTRL",
      action = act.ActivateTab(-1),
    },
    {
      -- Ctrl-Shift-p: コマンドパレットを開く。
      key = "p",
      mods = "SHIFT|CTRL",
      action = act.ActivateCommandPalette,
    },
    {
      -- Windows/Linux 用 Alt-p: Cmd-p 相当。コマンドパレットを開く。
      key = "p",
      mods = "ALT",
      action = act.ActivateCommandPalette,
    },
    {
      -- Ctrl-Shift-r: WezTerm 設定を再読み込みする。
      key = "r",
      mods = "SHIFT|CTRL",
      action = act.ReloadConfiguration,
    },
    {
      -- Windows/Linux 用 Alt-r: 設定を再読み込みする。
      key = "r",
      mods = "ALT",
      action = act.ReloadConfiguration,
    },
    {
      -- Ctrl-q s: pane サイズ変更モードに入る。
      key = "s",
      mods = "LEADER",
      action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }),
    },
    {
      -- Ctrl-q a: pane 移動モードに 1 秒だけ入る。
      key = "a",
      mods = "LEADER",
      action = act.ActivateKeyTable({ name = "activate_pane", timeout_milliseconds = 1000 }),
    },
  },

  -- 一時的なモード別キーバインド。
  key_tables = {
    -- Ctrl-q s で入る pane サイズ変更モード。
    resize_pane = {
      -- h: pane を左方向へ 1 セル縮める / 広げる。
      { key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },
      -- l: pane を右方向へ 1 セル縮める / 広げる。
      { key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },
      -- k: pane を上方向へ 1 セル縮める / 広げる。
      { key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },
      -- j: pane を下方向へ 1 セル縮める / 広げる。
      { key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },
      -- Enter: pane サイズ変更モードを終了する。
      { key = "Enter", action = "PopKeyTable" },
      -- Escape: pane サイズ変更モードを終了する。
      { key = "Escape", action = "PopKeyTable" },
    },

    -- Ctrl-q a で入る pane 移動モード。
    activate_pane = {
      -- h: 左の pane へ移動する。
      { key = "h", action = act.ActivatePaneDirection("Left") },
      -- l: 右の pane へ移動する。
      { key = "l", action = act.ActivatePaneDirection("Right") },
      -- k: 上の pane へ移動する。
      { key = "k", action = act.ActivatePaneDirection("Up") },
      -- j: 下の pane へ移動する。
      { key = "j", action = act.ActivatePaneDirection("Down") },
    },

    -- Ctrl-q [ で入る copy mode。Vim 風に移動できる。
    copy_mode = {
      -- h: カーソルを左へ移動する。
      { key = "h", mods = "NONE", action = act.CopyMode("MoveLeft") },
      -- j: カーソルを下へ移動する。
      { key = "j", mods = "NONE", action = act.CopyMode("MoveDown") },
      -- k: カーソルを上へ移動する。
      { key = "k", mods = "NONE", action = act.CopyMode("MoveUp") },
      -- l: カーソルを右へ移動する。
      { key = "l", mods = "NONE", action = act.CopyMode("MoveRight") },
      -- ^: 行の空白を除いた先頭へ移動する。
      { key = "^", mods = "NONE", action = act.CopyMode("MoveToStartOfLineContent") },
      -- $: 行末へ移動する。
      { key = "$", mods = "NONE", action = act.CopyMode("MoveToEndOfLineContent") },
      -- 0: 行頭へ移動する。
      { key = "0", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
      -- o: 選択範囲の反対側へ移動する。
      { key = "o", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEnd") },
      -- O: 選択範囲の反対側へ横方向に移動する。
      { key = "O", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEndHoriz") },
      -- ;: 直前の jump を繰り返す。
      { key = ";", mods = "NONE", action = act.CopyMode("JumpAgain") },
      -- w: 次の単語の先頭へ移動する。
      { key = "w", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
      -- b: 前の単語の先頭へ移動する。
      { key = "b", mods = "NONE", action = act.CopyMode("MoveBackwardWord") },
      -- e: 次の単語の末尾へ移動する。
      { key = "e", mods = "NONE", action = act.CopyMode("MoveForwardWordEnd") },
      -- t: 指定文字の直前へ前方 jump する。
      { key = "t", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = true } }) },
      -- f: 指定文字へ前方 jump する。
      { key = "f", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = false } }) },
      -- T: 指定文字の直後へ後方 jump する。
      { key = "T", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = true } }) },
      -- F: 指定文字へ後方 jump する。
      { key = "F", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = false } }) },
      -- G: scrollback の一番下へ移動する。
      { key = "G", mods = "NONE", action = act.CopyMode("MoveToScrollbackBottom") },
      -- g: scrollback の一番上へ移動する。
      { key = "g", mods = "NONE", action = act.CopyMode("MoveToScrollbackTop") },
      -- H: 表示領域の上へ移動する。
      { key = "H", mods = "NONE", action = act.CopyMode("MoveToViewportTop") },
      -- L: 表示領域の下へ移動する。
      { key = "L", mods = "NONE", action = act.CopyMode("MoveToViewportBottom") },
      -- M: 表示領域の中央へ移動する。
      { key = "M", mods = "NONE", action = act.CopyMode("MoveToViewportMiddle") },
      -- Ctrl-b: 1 ページ上へ移動する。
      { key = "b", mods = "CTRL", action = act.CopyMode("PageUp") },
      -- Ctrl-f: 1 ページ下へ移動する。
      { key = "f", mods = "CTRL", action = act.CopyMode("PageDown") },
      -- Ctrl-d: 半ページ下へ移動する。
      { key = "d", mods = "CTRL", action = act.CopyMode({ MoveByPage = 0.5 }) },
      -- Ctrl-u: 半ページ上へ移動する。
      { key = "u", mods = "CTRL", action = act.CopyMode({ MoveByPage = -0.5 }) },
      -- v: 通常の文字単位選択を開始する。
      { key = "v", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
      -- Ctrl-v: 矩形選択を開始する。
      { key = "v", mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },
      -- V: 行単位選択を開始する。
      { key = "V", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Line" }) },
      -- y: 選択範囲を clipboard へコピーする。
      { key = "y", mods = "NONE", action = act.CopyTo("Clipboard") },
      {
        -- Enter: 選択範囲を clipboard と primary selection へコピーして copy mode を閉じる。
        key = "Enter",
        mods = "NONE",
        action = act.Multiple({ { CopyTo = "ClipboardAndPrimarySelection" }, { CopyMode = "Close" } }),
      },
      -- Escape: copy mode を閉じる。
      { key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
      -- Ctrl-c: copy mode を閉じる。
      { key = "c", mods = "CTRL", action = act.CopyMode("Close") },
      -- q: copy mode を閉じる。
      { key = "q", mods = "NONE", action = act.CopyMode("Close") },
    },
  },
}

M.paste_status_cells = paste_status_cells

return M
