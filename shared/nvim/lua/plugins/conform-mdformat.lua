-- conform.nvim configuration
-- Adds mdformat as formatter for markdown files

return {
    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                markdown = { "mdformat" },
            },
            -- Optional: configure mdformat options
            formatters = {
                mdformat = {
                    -- mdformat options can go here if needed
                },
            },
        },
    },
}
