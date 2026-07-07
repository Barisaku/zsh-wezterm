local wezterm = require("wezterm")

-- WezTerm の action を短く書くための別名。
local act = wezterm.action

-- SSH profile ごとの安全設定を参照する。
local ssh_profiles = require("ssh_profiles")

-- 現在の workspace 名を変更する。
local function rename_workspace(_, _, line)
  -- 入力が空でなければ workspace 名として反映する。
  if line then
    wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
  end
end

-- 複数の clipboard 取得コマンドを順番に試し、最初に成功した結果を返す。
local function first_successful_command(commands)
  for _, command in ipairs(commands) do
    -- 外部コマンドを実行して clipboard 文字列を取得する。
    local ok, stdout = wezterm.run_child_process(command)

    -- 成功したら標準出力を clipboard 文字列として返す。
    if ok and stdout ~= nil then
      return stdout
    end
  end

  -- どのコマンドも失敗した場合は nil を返す。
  return nil
end

-- OS ごとに clipboard 文字列を取得する。
local function get_clipboard_text()
  -- macOS は pbpaste を使う。
  if wezterm.target_triple:find("darwin") then
    return first_successful_command({ { "pbpaste" } })
  end

  -- Windows / WSL は PowerShell の Get-Clipboard を使う。
  if wezterm.target_triple:find("windows") then
    return first_successful_command({
      { "powershell.exe", "-NoProfile", "-Command", "Get-Clipboard -Raw" },
    })
  end

  -- Linux は Wayland / X11 の代表的な clipboard コマンドを順番に試す。
  return first_successful_command({
    { "wl-paste", "--no-newline" },
    { "xclip", "-selection", "clipboard", "-out" },
    { "xsel", "--clipboard", "--output" },
  })
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

-- 安全ペースト。単一行はそのまま、複数行は profile に応じて拒否または確認する。
local function safe_paste(window, pane)
  -- clipboard の中身を取得する。
  local text = get_clipboard_text()

  -- clipboard が空なら何もしない。
  if text == nil or text == "" then
    return
  end

  -- 単一行なら通常通り貼り付ける。
  if not is_multiline(text) then
    pane:send_paste(text)
    return
  end

  -- prod など拒否設定の profile では複数行ペーストを止める。
  if ssh_profiles.blocks_multiline_paste(pane) then
    window:toast_notification("WezTerm", "本番 SSH では複数行ペーストを拒否しました", nil, 4000)
    return
  end

  -- 確認ダイアログに表示する行数。
  local line_count = count_lines(text)

  -- 確認ダイアログに表示する先頭 preview。
  local preview = preview_text(text, 3)

  -- 確認。Enter で貼り付け、Esc でキャンセル。
  window:perform_action(
    act.PromptInputLine({
      description = "複数行ペースト検出: "
        .. tostring(line_count)
        .. "行 / "
        .. preview
        .. " / Enterで貼り付け、Escでキャンセル",
      action = wezterm.action_callback(function(w, p, line)
        -- Esc の場合は nil になるので中止する。
        if line == nil then
          return
        end

        -- 確認済みの複数行テキストを貼り付ける。
        p:send_paste(text)
      end),
    }),
    pane
  )
end

return {
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
      -- Windows/Linux 用 Ctrl-Shift-c: 選択範囲を clipboard へコピーする。
      key = "c",
      mods = "CTRL|SHIFT",
      action = act.CopyTo("Clipboard"),
    },
    {
      -- Cmd-v: 安全ペーストを実行する。
      key = "v",
      mods = "SUPER",
      action = wezterm.action_callback(safe_paste),
    },
    {
      -- Ctrl-Shift-V: 安全ペーストを実行する。
      key = "v",
      mods = "CTRL|SHIFT",
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
      -- Ctrl-Shift-p: コマンドパレットを開く。
      key = "p",
      mods = "SHIFT|CTRL",
      action = act.ActivateCommandPalette,
    },
    {
      -- Ctrl-Shift-r: WezTerm 設定を再読み込みする。
      key = "r",
      mods = "SHIFT|CTRL",
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
