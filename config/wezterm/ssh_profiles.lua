local wezterm = require("wezterm")

local M = {}

-- window ごとの直近 SSH 表示状態。
-- set_config_overrides は比較的重いため、同じ状態なら呼ばない。
local last_override_state_by_window = {}

-- HOME が取れない環境では WezTerm の home_dir を使う。
local home = os.getenv("HOME") or wezterm.home_dir

-- wrapper なしの素の ssh を前面プロセス名で検出するかどうか。
-- get_foreground_process_name() はタブ切替時の体感速度に響くことがあるため、
-- 通常は zsh/fish/bash 共通の wezterm-ssh-log wrapper が送る user vars だけを見る。
local enable_plain_ssh_detection = os.getenv("WEZTERM_ENABLE_PLAIN_SSH_DETECTION") == "1"

-- フルパスからコマンド名だけを取り出す。
local function basename(path)
  if path == nil or path == "" then
    return ""
  end

  return path:gsub("\\", "/"):match("([^/]+)$") or path
end

-- wrapper を使わず普通に ssh した時の最低限の SSH 判定。
local function plain_ssh_info(pane)
  -- 現在 pane の前面で動いているプロセス名を取得する。
  local process_name = basename(pane:get_foreground_process_name())

  -- ssh か wezterm-ssh-log 以外なら SSH 扱いしない。
  if process_name ~= "ssh" and process_name ~= "wezterm-ssh-log" then
    return nil
  end

  -- 接続先名までは確実に取れないので generic SSH として扱う。
  return {
    profile = "default",
    host = "ssh",
    config = M.profiles.default,
  }
end

----------------------------------------------------
-- SSH profile 定義
----------------------------------------------------

-- SSH 中に使う読みやすさ優先の端末配色。
-- 背景色だけを変えると ANSI 色や選択範囲が沈むことがあるため、
-- foreground / cursor / selection / ANSI palette をまとめて上書きする。
local readable_terminal_colors = {
  -- 通常文字色。
  foreground = "#f8fafc",
  -- 通常背景色。実際の背景は profile の window_bg を使うため、ここでは近い暗色を指定する。
  background = "#111827",
  -- カーソル色。
  cursor_bg = "#facc15",
  -- カーソル枠色。
  cursor_border = "#facc15",
  -- カーソル上の文字色。
  cursor_fg = "#111827",
  -- 選択範囲の背景色。
  selection_bg = "#eab308",
  -- 選択範囲の文字色。
  selection_fg = "#111827",
  -- ANSI 基本 8 色。暗い背景で潰れにくい色にする。
  ansi = {
    "#0f172a",
    "#f87171",
    "#86efac",
    "#fde047",
    "#93c5fd",
    "#d8b4fe",
    "#67e8f9",
    "#e5e7eb",
  },
  -- ANSI bright 8 色。プロンプトや ls の強調表示が読めるよう少し明るめにする。
  brights = {
    "#475569",
    "#fca5a5",
    "#bbf7d0",
    "#fef08a",
    "#bfdbfe",
    "#e9d5ff",
    "#a5f3fc",
    "#ffffff",
  },
}

-- SSH 接続種別ごとの見た目と安全設定。
M.profiles = {
  -- 本番環境。強い背景色にし、複数行ペーストを拒否する。
  prod = {
    -- 右上ステータスに出す短いラベル。
    label = "PROD",
    -- 右上ステータスの文字色。
    fg = "#ffffff",
    -- 右上ステータスの背景色。
    bg = "#c53030",
    -- 非アクティブ SSH タブの背景色。裏にある SSH を通常タブと見分けるため淡い青にする。
    tab_bg = "#bae6fd",
    -- アクティブ SSH タブの背景色。
    active_tab_bg = "#ef4444",
    -- 非アクティブ SSH タブの文字色。
    tab_fg = "#082f49",
    -- SSH 中に上書きするウィンドウ背景色。
    window_bg = "#3b1113",
    -- 複数行ペーストを拒否するかどうか。
    block_multiline_paste = true,
  },

  -- ステージング環境。注意色にするが、複数行ペーストは二段階確認で許可する。
  staging = {
    -- 右上ステータスに出す短いラベル。
    label = "STG",
    -- 右上ステータスの文字色。
    fg = "#ffffff",
    -- 右上ステータスの背景色。
    bg = "#b7791f",
    -- 非アクティブ SSH タブの背景色。裏にある SSH を通常タブと見分けるため淡い青にする。
    tab_bg = "#bae6fd",
    -- アクティブ SSH タブの背景色。
    active_tab_bg = "#f59e0b",
    -- 非アクティブ SSH タブの文字色。
    tab_fg = "#082f49",
    -- SSH 中に上書きするウィンドウ背景色。
    window_bg = "#342606",
    -- 複数行ペーストを拒否するかどうか。
    block_multiline_paste = false,
  },

  -- ラボ環境。dev より注意、staging より軽い紫系にする。
  lab = {
    -- 右上ステータスに出す短いラベル。
    label = "LAB",
    -- 右上ステータスの文字色。
    fg = "#ffffff",
    -- 右上ステータスの背景色。
    bg = "#7c3aed",
    -- 非アクティブ SSH タブの背景色。裏にある SSH を通常タブと見分けるため淡い青にする。
    tab_bg = "#bae6fd",
    -- アクティブ SSH タブの背景色。
    active_tab_bg = "#8b5cf6",
    -- 非アクティブ SSH タブの文字色。
    tab_fg = "#082f49",
    -- SSH 中に上書きするウィンドウ背景色。
    window_bg = "#26133f",
    -- 複数行ペーストを拒否するかどうか。
    block_multiline_paste = false,
  },

  -- 開発環境。識別しやすい青系にする。
  dev = {
    -- 右上ステータスに出す短いラベル。
    label = "DEV",
    -- 右上ステータスの文字色。
    fg = "#ffffff",
    -- 右上ステータスの背景色。
    bg = "#2b6cb0",
    -- 非アクティブ SSH タブの背景色。裏にある SSH を通常タブと見分けるため淡い青にする。
    tab_bg = "#bae6fd",
    -- アクティブ SSH タブの背景色。
    active_tab_bg = "#3b82f6",
    -- 非アクティブ SSH タブの文字色。
    tab_fg = "#082f49",
    -- SSH 中に上書きするウィンドウ背景色。
    window_bg = "#06263a",
    -- 複数行ペーストを拒否するかどうか。
    block_multiline_paste = false,
  },

  -- profile 未指定の SSH。通常の ssh コマンド検出時もこれを使う。
  default = {
    -- 右上ステータスに出す短いラベル。
    label = "SSH",
    -- 右上ステータスの文字色。
    fg = "#ffffff",
    -- 右上ステータスの背景色。
    bg = "#64748b",
    -- 非アクティブ SSH タブの背景色。裏にある SSH を通常タブと見分けるため淡い青にする。
    tab_bg = "#bae6fd",
    -- アクティブ SSH タブの背景色。
    active_tab_bg = "#14b8a6",
    -- 非アクティブ SSH タブの文字色。
    tab_fg = "#082f49",
    -- SSH 中に上書きするウィンドウ背景色。
    window_bg = "#1e2930",
    -- 複数行ペーストを拒否するかどうか。
    block_multiline_paste = false,
  },

  -- Vagrant VM。通常 SSH とは別の緑系にして見分けやすくする。
  vagrant = {
    -- 右上ステータスに出す短いラベル。
    label = "VAGRANT",
    -- 右上ステータスの文字色。
    fg = "#052e16",
    -- 右上ステータスの背景色。
    bg = "#86efac",
    -- 非アクティブ SSH タブの背景色。裏にある Vagrant SSH を通常タブと見分けるため淡い緑にする。
    tab_bg = "#bbf7d0",
    -- アクティブ SSH タブの背景色。
    active_tab_bg = "#22c55e",
    -- 非アクティブ SSH タブの文字色。
    tab_fg = "#052e16",
    -- SSH 中に上書きするウィンドウ背景色。
    window_bg = "#0f2f1d",
    -- 複数行ペーストを拒否するかどうか。
    block_multiline_paste = false,
  },
}

----------------------------------------------------
-- Launch menu 接続先
----------------------------------------------------

-- WezTerm の launch menu に出したい SSH 接続先。
-- 実際の接続先に合わせてコメントを外して書き換える。
M.hosts = {
  -- 本番 host の例。ssh-prod 相当で起動する。
  -- { label = "PROD example-prod", profile = "prod", args = { "example-prod" } },

  -- port / user を指定する本番 host の例。name は表示名とログ名に使う。
  -- { label = "PROD example-prod :22", profile = "prod", args = { "-p", "22", "alice@example-prod" }, name = "example-prod" },

  -- ステージング host の例。
  -- { label = "STG example-staging", profile = "staging", args = { "example-staging" } },

  -- ラボ host の例。
  -- { label = "LAB example-lab", profile = "lab", args = { "example-lab" } },

  -- 開発 host の例。
  -- { label = "DEV example-dev", profile = "dev", args = { "example-dev" } },
}

-- profile 名から設定を引く。未定義なら default を使う。
local function profile_config(profile)
  return M.profiles[profile] or M.profiles.default
end

-- pane の状態から SSH 情報を検出する。
function M.detect(pane)
  -- wezterm-ssh-log が送った user vars を読む。
  local vars = pane:get_user_vars()

  -- SSH profile。prod / staging / lab / dev / default など。
  local profile = vars.WEZTERM_SSH_PROFILE

  -- SSH 接続先表示名。
  local host = vars.WEZTERM_SSH_HOST

  -- wrapper 経由でない場合は、通常は SSH 扱いしない。
  -- WEZTERM_ENABLE_PLAIN_SSH_DETECTION=1 の時だけ前面プロセス名から普通の ssh を検出する。
  if profile == nil or profile == "" then
    if enable_plain_ssh_detection then
      return plain_ssh_info(pane)
    end

    return nil
  end

  -- host が取れない場合でも表示が壊れないよう unknown にする。
  if host == nil or host == "" then
    host = "unknown"
  end

  -- WezTerm 側で使いやすい形にまとめて返す。
  return {
    profile = profile,
    host = host,
    config = profile_config(profile),
  }
end

-- format-tab-title event の TabInformation から SSH 情報を検出する。
-- タブ描画は頻繁に呼ばれるため、foreground process の問い合わせは避ける。
-- zsh の ssh wrapper / wezterm-ssh-log が送る user vars だけを見る。
function M.detect_tab(tab)
  local pane = tab.active_pane

  if pane == nil then
    return nil
  end

  local vars = pane.user_vars or {}
  local profile = vars.WEZTERM_SSH_PROFILE
  local host = vars.WEZTERM_SSH_HOST

  if profile == nil or profile == "" then
    return nil
  end

  if host == nil or host == "" then
    host = "unknown"
  end

  return {
    profile = profile,
    host = host,
    config = profile_config(profile),
  }
end

-- 背景 override の状態キーを作る。
local function override_state_key(info)
  if info == nil then
    return "local"
  end

  return table.concat({
    "ssh",
    info.profile or "default",
    info.config.window_bg or "",
  }, "|")
end

-- 右上ステータスに表示する部品を返す。
function M.right_status(pane)
  -- 現在 pane の SSH 情報を取る。
  local info = M.detect(pane)

  -- SSH でなければ何も表示しない。
  if info == nil then
    return {}
  end

  -- 右上に出す文字列。
  local label = info.config.label .. " " .. info.host

  -- 背景色、文字色、太字、本文の順に WezTerm format 用セルを返す。
  return {
    { Background = { Color = info.config.bg } },
    { Foreground = { Color = info.config.fg } },
    { Attribute = { Intensity = "Bold" } },
    { Text = " " .. label .. " " },
    { Attribute = { Intensity = "Normal" } },
  }
end

-- SSH profile に応じてウィンドウ背景色を上書きする。
function M.apply_window_overrides(window, pane)
  -- 現在 pane の SSH 情報を取る。
  local info = M.detect(pane)
  local next_state_key = override_state_key(info)
  local ok, raw_window_id = pcall(function()
    return window:window_id()
  end)
  local window_id = ok and tostring(raw_window_id) or tostring(window)

  -- 既存の一時上書き設定を取得する。
  local overrides = window:get_config_overrides() or {}

  -- タブ切替時に同じ状態を何度も反映すると重いので、変化がない場合は何もしない。
  if last_override_state_by_window[window_id] == next_state_key then
    return
  end

  -- SSH でない時は SSH 用の背景上書きを解除する。
  if info == nil then
    overrides.window_background_gradient = nil
    overrides.colors = nil
  else
    -- SSH 中は profile ごとの背景色を適用する。
    overrides.window_background_gradient = {
      colors = { info.config.window_bg },
    }
    -- SSH 中は背景色に合わせて文字色や ANSI 色も読みやすい配色へ固定する。
    overrides.colors = readable_terminal_colors
  end

  -- 上書き設定をウィンドウに反映する。
  window:set_config_overrides(overrides)
  last_override_state_by_window[window_id] = next_state_key
end

-- 現在 pane で複数行ペーストを拒否するかどうかを返す。
function M.blocks_multiline_paste(pane)
  -- 現在 pane の SSH 情報を取る。
  local info = M.detect(pane)

  -- SSH でなければ拒否しない。
  if info == nil then
    return false
  end

  -- profile 設定の block_multiline_paste をそのまま返す。
  return info.config.block_multiline_paste == true
end

-- WezTerm の launch menu 項目を作る。
function M.launch_menu()
  -- 先頭にはローカル zsh を入れる。
  local items = {
    {
      label = "Local zsh",
      args = { home .. "/bin/wezterm-login-shell" },
    },
  }

  -- M.hosts に定義した接続先を launch menu 項目へ変換する。
  for _, host in ipairs(M.hosts) do
    -- wezterm-ssh-log を profile 付きで起動する。
    local args = { home .. "/bin/wezterm-ssh-log", "--profile", host.profile or "default" }

    -- name があれば表示名 / ログ名として wrapper に渡す。
    if host.name ~= nil and host.name ~= "" then
      table.insert(args, "--name")
      table.insert(args, host.name)
    end

    -- wrapper の option と ssh の option を分ける。
    table.insert(args, "--")

    -- ssh に渡す実引数を追加する。
    for _, arg in ipairs(host.args or {}) do
      table.insert(args, arg)
    end

    -- WezTerm launch menu の 1 項目として追加する。
    table.insert(items, {
      label = host.label,
      args = args,
    })
  end

  -- 完成した launch menu を返す。
  return items
end

return M
