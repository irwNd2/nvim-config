return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.6", -- or latest stable
  dependencies = {
    "nvim-lua/plenary.nvim", -- Required dependency
  },
  config = function()
    require("telescope").setup({})
  end
}

