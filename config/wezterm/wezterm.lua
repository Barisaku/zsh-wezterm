local wezterm = require("wezterm")

-- WezTerm の設定テーブルを作る。
local config = wezterm.config_builder()

-- キーバインド定義を別ファイルから読み込む。
local keybinds = require("keybinds")

-- SSH profile / 背景色 / launch menu の定義を別ファイルから読み込む。
local ssh_profiles = require("ssh_profiles")

-- HOME が取れない環境では WezTerm の home_dir を使う。
local home = os.getenv("HOME") or wezterm.home_dir

-- WezTerm 自体が Windows 上で動いているかどうか。
local is_windows = wezterm.target_triple:find("windows") ~= nil

-- PATH の区切り文字。Unix 系は :、Windows は ;。
local path_separator = ":"

-- Windows 側では PATH の区切り文字を ; にする。
if is_windows then
  path_separator = ";"
end

-- Windows 上の WezTerm から見える WSL domain 一覧を取得する。
local function get_wsl_domains()
  if not is_windows then
    return {}
  end

  local ok, domains = pcall(wezterm.default_wsl_domains)
  if ok and type(domains) == "table" then
    for _, domain in ipairs(domains) do
      -- Windows 版 WezTerm から WSL を開く時も、WSL 側のログ保存 wrapper を優先する。
      -- wrapper がまだ入っていない初回環境では zsh、zsh もなければ bash に fallback する。
      domain.default_prog = {
        "bash",
        "-lc",
        "if [ -x \"$HOME/bin/wezterm-login-shell\" ]; then exec \"$HOME/bin/wezterm-login-shell\"; elif command -v zsh >/dev/null 2>&1; then exec zsh -l; else exec bash -l; fi",
      }

      -- WSL 起動時の既定ディレクトリ。
      domain.default_cwd = "~"
    end

    return domains
  end

  return {}
end

-- 既定で使う WSL domain を選ぶ。
-- 環境変数 WEZTERM_WSL_DISTRO=Ubuntu のように指定すると優先する。
local function select_default_wsl_domain(domains)
  local preferred = os.getenv("WEZTERM_WSL_DISTRO")

  if preferred ~= nil and preferred ~= "" then
    local preferred_domain = preferred
    if not preferred_domain:find("^WSL:") then
      preferred_domain = "WSL:" .. preferred_domain
    end

    for _, domain in ipairs(domains) do
      if domain.name == preferred_domain then
        return domain.name
      end
    end
  end

  for _, domain in ipairs(domains) do
    if domain.name ~= nil and domain.name ~= "" then
      return domain.name
    end
  end

  return nil
end

-- Windows 用の launch menu を作る。
-- SSH wrapper は WSL 側の ~/bin に置くため、Windows 側 menu には WSL 起動項目だけ出す。
local function windows_launch_menu(wsl_domains)
  local items = {}

  for _, domain in ipairs(wsl_domains) do
    if domain.name ~= nil and domain.name ~= "" then
      table.insert(items, {
        label = domain.name,
        domain = { DomainName = domain.name },
      })
    end
  end

  table.insert(items, {
    label = "Windows PowerShell",
    args = { "powershell.exe", "-NoLogo" },
  })

  table.insert(items, {
    label = "Windows cmd.exe",
    args = { "cmd.exe" },
  })

  return items
end

-- Windows 上で利用できる WSL domain。
local wsl_domains = get_wsl_domains()

-- Windows 上で既定にする WSL domain。
local default_wsl_domain = select_default_wsl_domain(wsl_domains)

if is_windows and #wsl_domains > 0 then
  -- default_wsl_domains() で得た設定に zsh 起動設定を足して WezTerm へ戻す。
  config.wsl_domains = wsl_domains
end

----------------------------------------------------
-- 起動と見た目
----------------------------------------------------

-- 設定ファイルを保存したら WezTerm に自動再読み込みさせる。
config.automatically_reload_config = true

-- フォント。UDEV Gothic 35NFLG を第一候補にし、無い場合は順番に fallback する。
config.font = wezterm.font_with_fallback({
  "UDEV Gothic 35NFLG",
  "UDEV Gothic NF",
  "UDEV Gothic",
  "JetBrains Mono",
  "Menlo",
})

-- フォントサイズ。
-- Windows は同じ数値でも大きく見えやすいため少し小さめにする。
if is_windows then
  config.font_size = 10.5
else
  config.font_size = 13.0
end

-- 新規ウィンドウの初期幅。文字セル数で指定する。通常の 80 列の約 2 倍。
config.initial_cols = 160

-- 新規ウィンドウの初期高さ。文字セル数で指定する。通常の 24 行の約 2 倍。
config.initial_rows = 48

-- 日本語入力などの IME を有効化する。
config.use_ime = true

-- ウィンドウ背景の透明度。1.0 が不透明、0.0 が完全透明。
config.window_background_opacity = 0.85

-- macOS の背景ぼかし量。値が大きいほど強くぼける。
config.macos_window_background_blur = 20

-- WezTerm から起動する shell でも ~/bin の helper を見つけられるよう PATH に追加する。
config.set_environment_variables = {
  PATH = home .. "/bin" .. path_separator .. (os.getenv("PATH") or ""),
}

----------------------------------------------------
-- タブ
----------------------------------------------------

-- OS 標準タイトルバーは隠し、リサイズ枠だけ残す。
config.window_decorations = "RESIZE"

-- タブバーを表示する。
config.show_tabs_in_tab_bar = true

-- タブが 1 つだけの時もタブバーを表示する。
-- 右上ステータスはタブバー右端に描画されるため、SSH host 表示を常に見えるようにする。
config.hide_tab_bar_if_only_one_tab = false

-- 右上ステータスの定期更新間隔。ミリ秒で指定する。
-- user var 変更時にも即時更新するが、保険として短めにしておく。
config.status_update_interval = 1000

-- タブ追加ボタンを非表示にする。
config.show_new_tab_button_in_tab_bar = false

-- タブの閉じるボタンを非表示にする。
config.show_close_tab_button_in_tabs = false

-- タイトルバー背景を透明扱いにして、背景色と馴染ませる。
config.window_frame = {
  -- 非アクティブ時のタイトルバー背景。
  inactive_titlebar_bg = "none",
  -- アクティブ時のタイトルバー背景。
  active_titlebar_bg = "none",
}

-- 通常時のウィンドウ背景色。SSH 中は ssh_profiles.lua 側で上書きする。
config.window_background_gradient = {
  colors = { "#000000" },
}

-- タブバーの色設定。
config.colors = {
  tab_bar = {
    -- タブ同士の境界線を消す。
    inactive_tab_edge = "none",
  },
}

-- タブ左側の装飾文字。
local SOLID_LEFT_ARROW = wezterm.nerdfonts.ple_lower_right_triangle

-- タブ右側の装飾文字。
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.ple_upper_left_triangle

-- タブの見た目を独自に整形する。
wezterm.on("format-tab-title", function(tab, tabs, panes, tab_config, hover, max_width)
  -- タブに紐づく SSH 情報。SSH 中でなければ nil。
  local ssh_info = ssh_profiles.detect_tab(tab)

  -- 非アクティブタブの背景色。
  local background = "#5c6d74"

  -- タブ文字色。
  local foreground = "#ffffff"

  -- 装飾の外側背景。none でウィンドウ背景に馴染ませる。
  local edge_background = "none"

  -- SSH タブは profile ごとの色にする。
  if ssh_info ~= nil then
    background = ssh_info.config.tab_bg or ssh_info.config.bg
    foreground = ssh_info.config.tab_fg or ssh_info.config.fg
  end

  -- アクティブタブだけ独自の色にする。
  if tab.is_active then
    if ssh_info ~= nil then
      background = ssh_info.config.active_tab_bg or ssh_info.config.bg
      foreground = ssh_info.config.active_tab_fg or ssh_info.config.tab_fg or ssh_info.config.fg
    else
      background = "#ae8b2d"
      foreground = "#ffffff"
    end
  end

  -- タブ装飾文字の色をタブ背景に合わせる。
  local edge_foreground = background

  -- タブタイトル。長すぎる場合は max_width に収まるよう右側を省略する。
  local title = "   " .. wezterm.truncate_right(tab.active_pane.title, max_width - 1) .. "   "

  -- 左装飾、タイトル、右装飾の順で描画する。
  return {
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = SOLID_LEFT_ARROW },
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = title },
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = SOLID_RIGHT_ARROW },
  }
end)

----------------------------------------------------
-- 基本動作
----------------------------------------------------

-- ペースト時の改行を WezTerm 側で勝手に変換しない。
config.canonicalize_pasted_newlines = "None"

-- スクロールバックの保持行数。
config.scrollback_lines = 100000

-- ウィンドウを閉じる時に必ず確認する。
config.window_close_confirmation = "AlwaysPrompt"

if is_windows then
  if default_wsl_domain ~= nil then
    -- Windows 版 WezTerm では cmd.exe ではなく WSL を既定 domain にする。
    config.default_domain = default_wsl_domain
  else
    -- WSL domain が見つからない時の fallback。WSL の既定 distro を起動する。
    config.default_prog = { "wsl.exe", "--cd", "~" }
  end
else
  -- macOS / Linux / WSL 内ではローカル作業ログを保存する wrapper を使う。
  config.default_prog = { home .. "/bin/wezterm-login-shell" }
end

if is_windows then
  -- Windows 版 WezTerm では WSL 起動項目を中心にする。
  config.launch_menu = windows_launch_menu(wsl_domains)
else
  -- macOS / Linux / WSL 内では ssh_profiles.lua の M.hosts から SSH 接続先を組み立てる。
  config.launch_menu = ssh_profiles.launch_menu()
end

----------------------------------------------------
-- 右上ステータスと SSH 背景色
----------------------------------------------------

-- 右上ステータスと SSH 背景色をまとめて更新する。
local function refresh_status_and_ssh_appearance(window, pane)
  -- SSH 中なら profile に応じて背景色を上書きする。
  ssh_profiles.apply_window_overrides(window, pane)

  -- 右上ステータスに表示するセルを順番に積む。
  local cells = {}

  -- resize_pane など、現在有効な key table 名を取得する。
  local key_table = window:active_key_table()

  -- key table が有効な時だけ右上に表示する。
  if key_table ~= nil then
    -- key table 表示の背景色。
    table.insert(cells, { Background = { Color = "#39424e" } })
    -- key table 表示の文字色。
    table.insert(cells, { Foreground = { Color = "#ffffff" } })
    -- key table 表示の本文。
    table.insert(cells, { Text = " TABLE " .. key_table .. " " })
  end

  -- 複数行ペースト確認など、見落としたくない警告を右上に表示する。
  if keybinds.paste_status_cells ~= nil then
    for _, cell in ipairs(keybinds.paste_status_cells(pane)) do
      table.insert(cells, cell)
    end
  end

  -- SSH profile / host 表示を追加する。
  for _, cell in ipairs(ssh_profiles.right_status(pane)) do
    table.insert(cells, cell)
  end

  -- 積んだセルを WezTerm の右上ステータスへ反映する。
  window:set_right_status(wezterm.format(cells))
end

-- 右上ステータス更新時に、キー操作モードと SSH 情報を表示する。
wezterm.on("update-right-status", function(window, pane)
  refresh_status_and_ssh_appearance(window, pane)
end)

-- キーバインド側から明示的に右上ステータスを更新したい時に使う。
wezterm.on("refresh-status", function(window, pane)
  refresh_status_and_ssh_appearance(window, pane)
end)

-- SSH wrapper から user var が届いた瞬間に表示を更新する。
-- これにより、タブ移動しなくても右上ヘッダーと背景色が即時反映される。
wezterm.on("user-var-changed", function(window, pane, name, value)
  if name == "WEZTERM_SSH_PROFILE" or name == "WEZTERM_SSH_HOST" then
    refresh_status_and_ssh_appearance(window, pane)
  end
end)

----------------------------------------------------
-- キーバインド
----------------------------------------------------

-- WezTerm 標準キーバインドを無効化し、自分で定義したものだけを使う。
config.disable_default_key_bindings = true

-- 通常キーバインド。
config.keys = keybinds.keys

-- resize_pane / copy_mode などの一時的なキーテーブル。
config.key_tables = keybinds.key_tables

-- leader キー。Ctrl-q を押した後、2 秒以内に続くキーを leader 操作として扱う。
config.leader = { key = "q", mods = "CTRL", timeout_milliseconds = 2000 }

return config
