return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts = opts or {}
            vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
                border = "rounded",
            })
            vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
                border = "rounded",
            })
            opts.diagnostics = opts.diagnostics or {}
            opts.diagnostics.float = opts.diagnostics.float or {}
            opts.diagnostics.float.border = "rounded"

            -- Do not clutter lines with virtual text for unused variables/imports/unreachable code (like VS Code)
            opts.diagnostics.virtual_text = opts.diagnostics.virtual_text or {}
            if type(opts.diagnostics.virtual_text) == "table" then
                local orig_format = opts.diagnostics.virtual_text.format
                opts.diagnostics.virtual_text.format = function(diagnostic)
                    if
                        (diagnostic._tags and diagnostic._tags.unnecessary)
                        or (diagnostic.tags and vim.tbl_contains(diagnostic.tags, 1))
                    then
                        return nil
                    end
                    if orig_format then
                        return orig_format(diagnostic)
                    end
                    return diagnostic.message
                end
            end

            -- Hide signs in gutter for unnecessary/unreachable code (dimmed text is enough, like VS Code)
            local orig_signs_show = vim.diagnostic.handlers.signs.show
            vim.diagnostic.handlers.signs.show = function(namespace, bufnr, diagnostics, sign_opts)
                local filtered = vim.tbl_filter(function(d)
                    return not ((d._tags and d._tags.unnecessary) or (d.tags and vim.tbl_contains(d.tags, 1)))
                end, diagnostics)
                return orig_signs_show(namespace, bufnr, filtered, sign_opts)
            end

            -- Ensure unreachable, unused, and unnecessary code is tagged with DiagnosticTag.Unnecessary
            -- and severity HINT so they are cleanly dimmed across all language servers (Python, C++, Rust, TS, Go, Lua, etc.)
            local function mark_unnecessary_diagnostics(items)
                if not items then
                    return
                end
                for _, item in ipairs(items) do
                    local code = tostring(item.code or "")
                    local msg = tostring(item.message or ""):lower()
                    local is_unnecessary = false

                    if item.tags and vim.tbl_contains(item.tags, 1) then
                        is_unnecessary = true
                    elseif code ~= "invalid-syntax" and code ~= "parse-error" then
                        if
                            code == "unreachable"
                            or code == "unreachable-code"
                            or code == "unreachable_code"
                            or code == "unreachable-match-case"
                            or code == "7027" -- TypeScript/JavaScript unreachable code
                            or code == "F841" -- Python unused variable
                            or code == "F401" -- Python unused import
                            or code == "B007" -- Python unused loop variable
                            or code == "B014" -- Python duplicate exception handler (unreachable)
                            or code == "B025" -- Python duplicate try block exception (unreachable)
                            or code == "UP036" -- Python unreachable version block
                            or code:match("^ARG%d") -- Python unused argument
                            or code:match("^%-Wunreachable%-code") -- Clang/GCC unreachable code
                            or code:match("^%-Wunused") -- Clang/GCC unused
                            or code:match("^unreachable")
                            or code:match("^unused")
                            or code == "dead_code"
                            or code == "dead-code"
                            or msg:match("unreachable code")
                            or msg:match("is unreachable")
                            or msg:match("is never read")
                            or msg:match("is never used")
                        then
                            is_unnecessary = true
                        end
                    end

                    if is_unnecessary then
                        item.severity = vim.diagnostic.severity.HINT
                        item.tags = item.tags or {}
                        if not vim.tbl_contains(item.tags, 1) then
                            table.insert(item.tags, 1) -- DiagnosticTag.Unnecessary
                        end
                    end
                end
            end

            local orig_publish = vim.lsp.diagnostic.on_publish_diagnostics
            vim.lsp.diagnostic.on_publish_diagnostics = function(err, result, ctx, config)
                if result and result.diagnostics then
                    mark_unnecessary_diagnostics(result.diagnostics)
                end
                return orig_publish(err, result, ctx, config)
            end

            local orig_on_diag = vim.lsp.diagnostic.on_diagnostic
            vim.lsp.diagnostic.on_diagnostic = function(err, result, ctx, config)
                if result and result.items then
                    mark_unnecessary_diagnostics(result.items)
                end
                return orig_on_diag(err, result, ctx, config)
            end

            vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.diagnostic.on_publish_diagnostics
            vim.lsp.handlers["textDocument/diagnostic"] = vim.lsp.diagnostic.on_diagnostic

            return opts
        end,
    },
}
