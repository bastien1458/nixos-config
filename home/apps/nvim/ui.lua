-- What the netrunner sees: a statusline cut like the bar, a neon edge on the
-- line under the cursor, and a start screen that lists quickhacks.
local M = {}

local modes = {
  n = { "SCAN", "Normal" },
  i = { "UPLOAD", "Insert" },
  v = { "TARGET", "Visual" },
  V = { "TARGET LINE", "Visual" },
  ["\22"] = { "TARGET BLOCK", "Visual" },
  s = { "SELECT", "Visual" },
  S = { "SELECT LINE", "Visual" },
  ["\19"] = { "SELECT BLOCK", "Visual" },
  R = { "OVERWRITE", "Replace" },
  c = { "QUICKHACK", "Command" },
  r = { "PROMPT", "Command" },
  ["!"] = { "SHELL", "Terminal" },
  t = { "JACKED IN", "Terminal" },
}

local function esc(text)
  return (text:gsub("%%", "%%%%"))
end

local function git()
  local summary = vim.b.minigit_summary
  if type(summary) ~= "table" or not summary.head_name then
    return ""
  end
  local out = "%#CyberStatusGit# " .. esc(summary.head_name)
  local diff = vim.b.minidiff_summary
  if type(diff) == "table" then
    for _, part in ipairs({ { "add", "+", "Ok" }, { "change", "~", "Warn" }, { "delete", "-", "Err" } }) do
      local n = diff[part[1]] or 0
      if n > 0 then
        out = out .. " %#CyberStatus" .. part[3] .. "#" .. part[2] .. n
      end
    end
  end
  return out .. "%#CyberStatusDim# // "
end

local special = { ministarter = "NIGHT CITY", minifiles = "FILE SYSTEM", minipick = "SCAN", help = "DATABASE" }

local function file()
  if vim.bo.buftype ~= "" then
    local label = special[vim.bo.filetype] or (vim.bo.buftype == "terminal" and "TERMINAL") or vim.bo.filetype:upper()
    return "%#CyberStatusFile#" .. esc(label ~= "" and label or "SCRATCH")
  end
  local name = vim.fn.expand("%:~:.")
  if name == "" then
    name = "[NO DATASHARD]"
  end
  local out = "%#CyberStatusFile#" .. esc(name)
  if vim.bo.modified then
    out = out .. " %#CyberStatusWarn#[UNSAVED]"
  end
  if vim.bo.readonly or not vim.bo.modifiable then
    out = out .. " %#CyberStatusErr#[RO]"
  end
  return out
end

local function diagnostics()
  local count = vim.diagnostic.count(0)
  local s = vim.diagnostic.severity
  local out = ""
  for _, part in ipairs({ { s.ERROR, "E", "Err" }, { s.WARN, "W", "Warn" }, { s.INFO, "I", "Link" }, { s.HINT, "H", "Dim" } }) do
    local n = count[part[1]] or 0
    if n > 0 then
      out = out .. "%#CyberStatus" .. part[3] .. "#" .. part[2] .. n .. " "
    end
  end
  return out ~= "" and out .. "%#CyberStatusDim#// " or ""
end

local function links()
  local names = {}
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    table.insert(names, client.name)
  end
  if #names == 0 then
    return ""
  end
  return "%#CyberStatusLink#⌁ " .. esc(table.concat(names, " ")) .. "%#CyberStatusDim# // "
end

function M.statusline()
  local m = vim.api.nvim_get_mode().mode
  local mode = modes[m] or modes[m:sub(1, 1)] or { m:upper(), "Normal" }
  local block, edge = "%#Cyber" .. mode[2] .. "#", "%#Cyber" .. mode[2] .. "Edge#"
  local ft = (vim.bo.buftype == "" and vim.bo.filetype ~= "") and esc(vim.bo.filetype:upper()) .. " // " or ""
  -- same signature as the prompt: a neon half block, then the inverted label
  return table.concat({
    edge,
    "▌",
    block,
    " ",
    mode[1],
    " ",
    edge,
    "",
    "%#CyberStatusDim# // ",
    git(),
    file(),
    "%=",
    diagnostics(),
    links(),
    "%#CyberStatusDim#",
    ft,
    "%p%% ",
    edge,
    "",
    block,
    " %l:%-2c ",
    edge,
    "▐",
  })
end

-- the GTK rows of the deck have a 3px accent inset where the content starts: same here
function M.statuscolumn()
  local current = vim.v.relnum == 0
  if vim.v.virtnum ~= 0 then
    return "%s"
  end
  local relative = vim.wo[vim.g.statusline_winid].relativenumber and not current
  local number = relative and vim.v.relnum or vim.v.lnum
  local edge = current and "%#CyberEdge#▌" or " "
  return "%s%=" .. (current and "%#CursorLineNr#" or "%#LineNr#") .. number .. " " .. edge
end

local skyline = {
  "         ▐▌          ▄",
  "    ▄▄   ▐▌   ▄▄    ███    ▄▄",
  "   ████  ██▌  ██   ▐███▌  ████  ▄",
  "   █▀▀█ ▐███  ██▄▄▄████▌  █▀▀█  █▌",
  "   █▄▄█▄████▄▄█████████▄▄▄█▄▄█▄███▌",
  "   ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀",
  "",
  "  C Y B E R D E C K   //   N V I M",
}

local whispers = { "the wall is listening", "we see you", "let us in", "it remembers your name", "0.0.0.0 is calling" }

local function hack(name, cost, action)
  return { name = string.format("%-20s [%d RAM]", name, cost), action = action, section = "QUICKHACKS" }
end

local function pick(source, opts)
  return function()
    local ok, picker = pcall(require, "mini.pick")
    if ok then
      picker.builtin[source](nil, opts)
    end
  end
end

local function recent()
  local items = {}
  for _, path in ipairs(vim.v.oldfiles) do
    if #items == 6 then
      break
    end
    if vim.fn.filereadable(path) == 1 then
      table.insert(items, {
        name = vim.fn.fnamemodify(path, ":~"),
        action = "edit " .. vim.fn.fnameescape(path),
        section = "RECENT DATASHARDS",
      })
    end
  end
  return items
end

local function starter()
  local ok, mini = pcall(require, "mini.starter")
  if not ok then
    return
  end
  mini.setup({
    evaluate_single = true,
    header = table.concat(skyline, "\n"),
    items = {
      hack("SCAN DATASHARDS", 2, pick("files")),
      hack("TRACE STRING", 3, pick("grep_live")),
      hack("NEW DATASHARD", 1, "enew | startinsert"),
      hack("ACCESS FIRMWARE", 4, function()
        vim.cmd.cd(vim.fn.fnameescape(vim.g.cyberdeck_dotfiles or "~"))
        pick("files")()
      end),
      hack("BREACH PROTOCOL", 3, function()
        pcall(vim.system, { "quickshell", "-c", "cyberdeck", "ipc", "call", "breach", "open" })
      end),
      hack("FLATLINE", 0, "qall"),
      recent,
    },
    footer = function()
      local palette = require("cyberdeck.theme").palette or {}
      local lines = { (palette.name or "CYBERDECK"):upper() .. "  //  BLACKWALL INTEGRITY 99.97%" }
      if math.random(10) == 1 then
        table.insert(lines, "// " .. whispers[math.random(#whispers)])
      end
      return table.concat(lines, "\n")
    end,
    content_hooks = {
      mini.gen_hook.adding_bullet("▌ "),
      mini.gen_hook.aligning("center", "center"),
    },
    query_updaters = "abcdefghijklmnopqrstuvwxyz0123456789_-.~/",
  })
end

function M.setup()
  vim.o.statusline = "%!v:lua.require'cyberdeck.ui'.statusline()"
  vim.o.statuscolumn = "%!v:lua.require'cyberdeck.ui'.statuscolumn()"
  starter()
  -- the mode block changes colour as soon as the mode does
  vim.api.nvim_create_autocmd({ "ModeChanged", "DiagnosticChanged", "LspAttach", "LspDetach" }, {
    group = vim.api.nvim_create_augroup("cyberdeck-statusline", {}),
    callback = function()
      vim.cmd.redrawstatus()
    end,
  })
end

return M
