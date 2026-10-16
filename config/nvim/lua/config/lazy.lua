local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        lazypath,
    })
end

vim.opt.rtp:prepend(lazypath)

-- Home Manager keeps ~/.config in the read-only Nix store. Keep the writable
-- plugin lock in state, seeded from the repository on first use.
local lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json"
if vim.fn.filereadable(lockfile) == 0 then
    local seed = vim.fn.stdpath("config") .. "/lazy-lock.json"
    if vim.fn.filereadable(seed) == 1 then
        vim.fn.mkdir(vim.fn.stdpath("state"), "p")
        vim.fn.writefile(vim.fn.readfile(seed), lockfile)
    end
end

require("lazy").setup("plugins", { lockfile = lockfile })
