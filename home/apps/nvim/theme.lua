-- The live palette: theme.json written by cyberdeck-theme, watched so that
-- switching OS or wallpaper from the bar recolours every open nvim at once.
local M = {}

local state = (vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")) .. "/cyberdeck"

local function read()
  local fh = io.open(state .. "/theme.json")
  if fh then
    local ok, theme = pcall(vim.json.decode, fh:read("*a"))
    fh:close()
    if ok and type(theme) == "table" and type(theme.palette) == "table" and theme.palette.base16 then
      return theme.palette
    end
  end
  return vim.g.cyberdeck_fallback
end

-- statusline blocks, one per mode family
local modes = {
  Normal = "primary",
  Insert = "warn",
  Visual = "tertiary",
  Replace = "danger",
  Command = "secondary",
  Terminal = "ok",
}

local function groups(r)
  local g = {
    -- the terminal shows through: kitty already paints bg with its opacity
    Normal = { fg = r.fg },
    NormalNC = { fg = r.fg },
    SignColumn = {},
    FoldColumn = { fg = r.muted },
    EndOfBuffer = { fg = r.bg },
    LineNr = { fg = r.muted },
    LineNrAbove = { fg = r.muted },
    LineNrBelow = { fg = r.muted },
    CursorLine = { bg = r.surface },
    CursorLineNr = { fg = r.warn, bold = true },
    CursorLineSign = { bg = r.surface },
    CyberEdge = { fg = r.primary, bg = r.surface },
    ColorColumn = { bg = r.surface },
    WinSeparator = { fg = r.overlay },
    Comment = { fg = r.muted, italic = true },
    Directory = { fg = r.secondary },
    Title = { fg = r.primary, bold = true },
    MatchParen = { fg = r.warn, bold = true, underline = true },
    NonText = { fg = r.overlay },
    Whitespace = { fg = r.overlay },

    Visual = { bg = r.overlay },
    Search = { fg = r.bg, bg = r.warn },
    CurSearch = { fg = r.bg, bg = r.danger, bold = true },
    IncSearch = { fg = r.bg, bg = r.danger, bold = true },
    Substitute = { fg = r.bg, bg = r.alt },
    CyberUpload = { fg = r.bg, bg = r.primary },

    NormalFloat = { fg = r.fg, bg = r.surface },
    FloatBorder = { fg = r.primary, bg = r.surface },
    FloatTitle = { fg = r.bg, bg = r.primary, bold = true },
    FloatFooter = { fg = r.subtle, bg = r.surface },
    Pmenu = { fg = r.fg, bg = r.surface },
    PmenuSel = { fg = r.bg, bg = r.primary, bold = true },
    PmenuKind = { fg = r.secondary, bg = r.surface },
    PmenuExtra = { fg = r.muted, bg = r.surface },
    PmenuSbar = { bg = r.surface },
    PmenuThumb = { bg = r.primary },
    PmenuMatch = { fg = r.warn, bg = r.surface, bold = true },
    PmenuMatchSel = { fg = r.bg, bg = r.primary, bold = true, underline = true },

    StatusLine = { fg = r.subtle, bg = r.surface },
    StatusLineNC = { fg = r.muted, bg = r.surface },
    CyberStatusFile = { fg = r.bright, bg = r.surface, bold = true },
    CyberStatusDim = { fg = r.muted, bg = r.surface },
    CyberStatusGit = { fg = r.tertiary, bg = r.surface, bold = true },
    CyberStatusLink = { fg = r.secondary, bg = r.surface },
    CyberStatusOk = { fg = r.ok, bg = r.surface },
    CyberStatusWarn = { fg = r.warn, bg = r.surface, bold = true },
    CyberStatusErr = { fg = r.danger, bg = r.surface, bold = true },
    TabLine = { fg = r.subtle, bg = r.surface },
    TabLineSel = { fg = r.bg, bg = r.primary, bold = true },
    TabLineFill = { bg = r.bg },
    WinBar = { fg = r.subtle },
    WinBarNC = { fg = r.muted },
    MsgArea = { fg = r.fg },
    ModeMsg = { fg = r.warn, bold = true },
    MoreMsg = { fg = r.ok, bold = true },
    ErrorMsg = { fg = r.danger, bold = true },
    WarningMsg = { fg = r.warn },

    DiagnosticError = { fg = r.danger },
    DiagnosticWarn = { fg = r.warn },
    DiagnosticInfo = { fg = r.secondary },
    DiagnosticHint = { fg = r.tertiary },
    DiagnosticOk = { fg = r.ok },
    DiagnosticVirtualTextError = { fg = r.danger, italic = true },
    DiagnosticVirtualTextWarn = { fg = r.warn, italic = true },
    DiagnosticVirtualTextInfo = { fg = r.secondary, italic = true },
    DiagnosticVirtualTextHint = { fg = r.tertiary, italic = true },
    DiagnosticUnderlineError = { sp = r.danger, undercurl = true },
    DiagnosticUnderlineWarn = { sp = r.warn, undercurl = true },

    MiniStarterHeader = { fg = r.primary, bold = true },
    MiniStarterSection = { fg = r.warn, bold = true },
    MiniStarterItem = { fg = r.fg },
    MiniStarterItemBullet = { fg = r.primary },
    MiniStarterItemPrefix = { fg = r.danger, bold = true },
    MiniStarterCurrent = { fg = r.bright, bold = true },
    MiniStarterQuery = { fg = r.warn, bold = true },
    MiniStarterFooter = { fg = r.muted, italic = true },
    MiniPickBorder = { fg = r.primary, bg = r.surface },
    MiniPickBorderBusy = { fg = r.warn, bg = r.surface },
    MiniPickBorderText = { fg = r.bg, bg = r.primary, bold = true },
    MiniPickPrompt = { fg = r.warn, bg = r.surface, bold = true },
    MiniPickPromptPrefix = { fg = r.warn, bg = r.surface, bold = true },
    MiniPickPromptCaret = { fg = r.primary, bg = r.surface },
    MiniPickMatchCurrent = { bg = r.overlay, bold = true },
    MiniPickMatchRanges = { fg = r.warn, bold = true },
    MiniClueTitle = { fg = r.bg, bg = r.primary, bold = true },
    MiniClueBorder = { fg = r.primary, bg = r.surface },
    MiniClueDescGroup = { fg = r.tertiary, bg = r.surface },
    MiniClueNextKey = { fg = r.warn, bg = r.surface, bold = true },
    MiniFilesBorder = { fg = r.primary, bg = r.surface },
    MiniFilesTitleFocused = { fg = r.bg, bg = r.primary, bold = true },
    MiniFilesTitle = { fg = r.subtle, bg = r.surface },
    MiniIndentscopeSymbol = { fg = r.deep },
    MiniDiffSignAdd = { fg = r.ok },
    MiniDiffSignChange = { fg = r.warn },
    MiniDiffSignDelete = { fg = r.danger },
  }
  for mode, role in pairs(modes) do
    g["Cyber" .. mode] = { fg = r.bg, bg = r[role], bold = true }
    g["Cyber" .. mode .. "Edge"] = { fg = r[role], bg = r.surface }
  end
  return g
end

function M.apply()
  local palette = read()
  if type(palette) ~= "table" or not palette.base16 then
    return
  end
  M.palette = palette
  local ok, base16 = pcall(require, "mini.base16")
  if ok then
    base16.setup({ palette = palette.base16, use_cterm = false })
  end
  for name, spec in pairs(groups(palette.roles)) do
    vim.api.nvim_set_hl(0, name, spec)
  end
  vim.g.colors_name = "cyberdeck"
  vim.api.nvim_exec_autocmds("User", { pattern = "CyberdeckTheme", modeline = false })
end

local watcher, debounce

-- cyberdeck-theme replaces theme.json atomically: watch the directory, not the file
local function watch()
  if watcher or vim.fn.isdirectory(state) == 0 then
    return
  end
  watcher, debounce = vim.uv.new_fs_event(), vim.uv.new_timer()
  if not watcher or not debounce then
    return
  end
  watcher:start(state, {}, function(err, name)
    if err or (name and name ~= "theme.json") then
      return
    end
    debounce:stop()
    debounce:start(
      120,
      0,
      vim.schedule_wrap(function()
        M.apply()
        vim.cmd.redraw({ bang = true })
      end)
    )
  end)
end

function M.setup()
  M.apply()
  watch()
end

return M
