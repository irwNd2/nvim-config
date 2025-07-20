local M = {}

local function open_dir_picker(base_dir)
  local Path = require("plenary.path")
  local uv = vim.loop
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values

  base_dir = base_dir or uv.cwd()
  local results = { ".." }

  -- Only list immediate children (file or folder)
  local fd_cmd = 'fd --max-depth 1 . "' .. base_dir .. '"'
  local handle = io.popen(fd_cmd)
  if handle then
    for line in handle:lines() do
      if line ~= "." then
        table.insert(results, line)
      end
    end
    handle:close()
  end

  pickers.new({}, {
    prompt_title = "Browse: " .. base_dir,
    finder = finders.new_table({ results = results }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()[1]
        local target_path

        if selection == ".." then
          target_path = Path:new(base_dir):parent():absolute()
          actions.close(prompt_bufnr)
          open_dir_picker(target_path)
          return
        else
          -- Prevent double absolute path issue
          if Path:new(selection):is_absolute() then
            target_path = Path:new(selection):absolute()
          else
            target_path = Path:new(base_dir, selection):absolute()
          end
        end

        if vim.fn.isdirectory(target_path) == 1 then
          -- If it's a directory, stay in telescope and reopen inside it
          actions.close(prompt_bufnr)
          open_dir_picker(target_path)
        else
			actions.close(prompt_bufnr)

			vim.cmd("cd " .. vim.fn.fnameescape(Path:new(target_path):parent():absolute()))
			vim.cmd("edit! " .. vim.fn.fnameescape(target_path))

			print("Changed directory to: " .. vim.fn.getcwd())

			if os.getenv("TMUX") then
			  os.execute("tmux send-keys -t %0 'cd " .. vim.fn.getcwd() .. " && clear' C-m")
			end
        end
      end)
      return true
    end,
  }):find()
end

M.change_dir_with_telescope = function()
  open_dir_picker()
end

return M

