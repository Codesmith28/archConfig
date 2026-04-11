return {
    "saghen/blink.cmp",
    opts = {
        enabled = function()
            local bo = vim.bo

            -- 1. Disable if the buffer is locked (fixes E21)
            if not bo.modifiable then
                return false
            end

            -- 2. Disable in special plugin UI buffers (fixes E382)
            if bo.buftype == "prompt" or bo.buftype == "nofile" then
                return false
            end

            -- 3. Default behavior: keep enabled everywhere else
            return vim.b.completion ~= false
        end,
    },
}
