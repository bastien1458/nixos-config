-- Cyberdeck Neovim: options, mini.nvim modules, language servers and keys.
-- Colours live in theme.lua, the statusline and start screen in ui.lua.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local o = vim.opt
o.termguicolors = true
o.number = true
o.relativenumber = true
o.cursorline = true
o.signcolumn = "yes"
o.laststatus = 3
o.showmode = false
o.scrolloff = 6
o.sidescrolloff = 8
o.wrap = false
o.mouse = "a"
o.clipboard = "unnamedplus"
o.undofile = true
o.ignorecase = true
o.smartcase = true
o.splitright = true
o.splitbelow = true
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.updatetime = 250
o.timeoutlen = 400
o.confirm = true
o.list = true
o.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
-- heavy straight separators, square corners everywhere, like the shell
o.fillchars = {
  eob = " ",
  fold = " ",
  vert = "┃",
  horiz = "━",
  horizup = "┻",
  horizdown = "┳",
  vertleft = "┫",
  vertright = "┣",
  verthoriz = "╋",
}
o.winborder = "single"
o.pumheight = 12
o.completeopt = { "menuone", "noselect", "popup", "fuzzy" }
-- the same blinking neon block as kitty
o.guicursor = "n-v-c-sm:block-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor,a:blinkwait500-blinkoff400-blinkon400"

local function load(name)
  local ok, mod = pcall(require, name)
  return ok and mod or nil
end

local function setup(name, opts)
  local mod = load(name)
  if mod then
    mod.setup(opts or {})
  end
end

require("cyberdeck.theme").setup()

setup("mini.icons")
setup("mini.pairs")
setup("mini.surround")
setup("mini.ai")
setup("mini.git")
setup("mini.extra")
setup("mini.diff", { view = { style = "sign", signs = { add = "▌", change = "▌", delete = "▁" } } })
setup("mini.indentscope", { symbol = "▏" })
setup("mini.files", { windows = { preview = true, width_preview = 60 } })

setup("mini.pick", {
  window = {
    prompt_prefix = "▶ ",
    config = function()
      local height, width = math.floor(vim.o.lines * 0.6), math.floor(vim.o.columns * 0.6)
      return {
        anchor = "NW",
        height = height,
        width = width,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
      }
    end,
  },
})

local hipatterns = load("mini.hipatterns")
if hipatterns then
  hipatterns.setup({
    highlighters = {
      hex_color = hipatterns.gen_highlighter.hex_color(),
      fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
      hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
      todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
      note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
    },
  })
end

local clue = load("mini.clue")
if clue then
  clue.setup({
    triggers = {
      { mode = "n", keys = "<Leader>" },
      { mode = "x", keys = "<Leader>" },
      { mode = "n", keys = "g" },
      { mode = "x", keys = "g" },
      { mode = "n", keys = "z" },
      { mode = "x", keys = "z" },
      { mode = "n", keys = "[" },
      { mode = "n", keys = "]" },
      { mode = "n", keys = "<C-w>" },
      { mode = "n", keys = "'" },
      { mode = "n", keys = "`" },
      { mode = "n", keys = '"' },
      { mode = "x", keys = '"' },
      { mode = "i", keys = "<C-r>" },
      { mode = "c", keys = "<C-r>" },
    },
    clues = {
      clue.gen_clues.builtin_completion(),
      clue.gen_clues.g(),
      clue.gen_clues.marks(),
      clue.gen_clues.registers(),
      clue.gen_clues.windows(),
      clue.gen_clues.z(),
      { mode = "n", keys = "<Leader>l", desc = "+LINK (LSP)" },
    },
    window = { delay = 300, config = { width = "auto" } },
  })
end

require("cyberdeck.ui").setup()

-- tree-sitter: the parsers come from nix, highlighting starts per buffer
vim.treesitter.language.register("qmljs", "qml")
vim.treesitter.language.register("bash", "sh")
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("cyberdeck-treesitter", {}),
  callback = function(ev)
    pcall(vim.treesitter.start, ev.buf)
  end,
})

-- language servers, without nvim-lspconfig
local flake = string.format('(builtins.getFlake "%s")', vim.g.cyberdeck_dotfiles or "/etc/nixos")
vim.lsp.config("nixd", {
  cmd = { "nixd" },
  filetypes = { "nix" },
  root_markers = { "flake.nix", ".git" },
  settings = {
    nixd = {
      formatting = { command = { "nixfmt" } },
      options = {
        nixos = { expr = flake .. ".nixosConfigurations.hello.options" },
        home_manager = {
          expr = flake .. ".nixosConfigurations.hello.options.home-manager.users.type.getSubOptions []",
        },
      },
    },
  },
})
vim.lsp.config("lua_ls", {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".git" },
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = { library = { vim.env.VIMRUNTIME }, checkThirdParty = false },
      telemetry = { enable = false },
    },
  },
})
vim.lsp.config("qmlls", {
  cmd = { "qmlls", "-E" },
  filetypes = { "qml", "qmljs" },
  root_markers = { ".qmlls.ini", ".git" },
})
vim.lsp.enable({ "nixd", "lua_ls", "qmlls" })

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("cyberdeck-lsp", {}),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
  end,
})

local severity = vim.diagnostic.severity
vim.diagnostic.config({
  severity_sort = true,
  virtual_text = { prefix = "▌", spacing = 2 },
  float = { header = " DIAGNOSTIC SCAN ", prefix = "▌ " },
  signs = { text = { [severity.ERROR] = "✖", [severity.WARN] = "▲", [severity.INFO] = "●", [severity.HINT] = "◆" } },
})

-- an upload flash on every yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("cyberdeck-yank", {}),
  callback = function()
    vim.hl.on_yank({ higroup = "CyberUpload", timeout = 180 })
  end,
})

-- keys: <Space> opens the quickhack list (mini.clue shows it)
local function map(lhs, rhs, desc, mode)
  vim.keymap.set(mode or "n", lhs, rhs, { desc = desc })
end
local function call(module, path, ...)
  local args = { ... }
  return function()
    local fn = load(module)
    if not fn then
      return
    end
    for key in path:gmatch("[^.]+") do
      fn = fn[key]
    end
    fn(unpack(args))
  end
end

map("<Leader>f", call("mini.pick", "builtin.files"), "Scan datashards (files)")
map("<Leader>/", call("mini.pick", "builtin.grep_live"), "Trace string (grep)")
map("<Leader>b", call("mini.pick", "builtin.buffers"), "Buffers")
map("<Leader>h", call("mini.pick", "builtin.help"), "Help")
map("<Leader>r", call("mini.extra", "pickers.oldfiles"), "Recent datashards")
map("<Leader>d", call("mini.extra", "pickers.diagnostic"), "Diagnostics")
map("<Leader>k", call("mini.extra", "pickers.keymaps"), "Keymaps")
map("<Leader>s", call("mini.starter", "open"), "Start screen")
map("<Leader>e", function()
  local path = vim.api.nvim_buf_get_name(0)
  require("mini.files").open(vim.uv.fs_stat(path) and path or nil)
end, "Explore files")
map("<Leader>lf", function()
  vim.lsp.buf.format()
end, "Format")
map("<Leader>lr", vim.lsp.buf.rename, "Rename")
map("<Leader>la", vim.lsp.buf.code_action, "Code action")
map("<Leader>ld", vim.diagnostic.open_float, "Line diagnostics")
map("gd", vim.lsp.buf.definition, "Definition")
map("<Leader>w", "<Cmd>write<CR>", "Write")
map("<Leader>q", "<Cmd>quit<CR>", "Quit")
map("<Esc>", "<Cmd>nohlsearch<CR>", "Clear search")
-- the same hjkl as the niri focus bindings
map("<C-h>", "<C-w>h", "Focus left")
map("<C-j>", "<C-w>j", "Focus down")
map("<C-k>", "<C-w>k", "Focus up")
map("<C-l>", "<C-w>l", "Focus right")

-- completion: Tab walks the menu, Enter takes the selected item
local keys = {
  cr = vim.keycode("<CR>"),
  accept = vim.keycode("<C-y>"),
  accept_cr = vim.keycode("<C-y><CR>"),
}
vim.keymap.set("i", "<Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
end, { expr = true, desc = "Next completion" })
vim.keymap.set("i", "<S-Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
end, { expr = true, desc = "Previous completion" })
vim.keymap.set("i", "<CR>", function()
  if vim.fn.pumvisible() == 1 then
    return vim.fn.complete_info({ "selected" }).selected ~= -1 and keys.accept or keys.accept_cr
  end
  local autopairs = load("mini.pairs")
  return autopairs and autopairs.cr() or keys.cr
end, { expr = true, replace_keycodes = false, desc = "Accept completion" })
