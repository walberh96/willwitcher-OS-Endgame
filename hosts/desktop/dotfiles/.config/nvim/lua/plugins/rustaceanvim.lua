-- lua/plugins/rustaceanvim.lua
return {
    "mrcjkb/rustaceanvim",
    version = "^6", -- recomendado
    lazy = false, -- el plugin ya es lazy internamente
    init = function()
        -- Mezcla dos on_attach sin perder el que ya tengas
        local function chain_on_attach(a, b)
            if a and b then
                return function(client, bufnr)
                    a(client, bufnr); b(client, bufnr)
                end
            end
            return a or b
        end

        -- Añade omni-completion en Ctrl-Space/Ctrl-@ solo para este buffer
        local function add_omnikeys(bufnr)
            vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
            local opts = { buffer = bufnr, silent = true }
            vim.keymap.set("i", "<C-Space>", "<C-x><C-o>", opts)
            vim.keymap.set("i", "<C-@>", "<C-x><C-o>", opts) -- algunos terminales mandan C-@
        end

        -- Extiende tu config global si ya existía
        local rc = vim.g.rustaceanvim or {}
        rc.server = rc.server or {}

        rc.server.on_attach = chain_on_attach(rc.server.on_attach, function(client, bufnr)
            if client and client.name == "rust_analyzer" then
                add_omnikeys(bufnr)
            end
        end)

        vim.g.rustaceanvim = rc
    end,
}
