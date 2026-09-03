local function connect_to_godot_server()
  -- Check if project.godot exists in current directory
  local project_file = vim.fn.getcwd() .. "/project.godot"
  if vim.fn.filereadable(project_file) == 1 then
    local pipe_path = vim.fn.getcwd() .. "/nvim_server.pipe"

    -- Create the pipe if it doesn't exist, then connect
    local success = vim.fn.serverstart(pipe_path)
    if success then
      print("Connected to Godot server via " .. pipe_path)
    else
      print("Failed to create/connect to Godot server pipe: " .. pipe_path)
    end

    local dap = require("dap")

    dap.adapters.godot = {
      type = 'server',
      host = '127.0.0.1',
      port = 6006,
    }

    dap.configurations.gdscript = {
      {
        type = 'godot',
        request = 'launch',
        name = 'Launch scene',
        project = '${workspaceFolder}',
        launch_scene = true,
      },
    }

    dap.configurations.cs = {
      {
        type = 'godot',
        request = 'launch',
        name = 'Launch scene',
        project = '${workspaceFolder}',
        launch_scene = true,
      },
    }
  end
end

-- Auto-connect when Neovim starts
vim.api.nvim_create_autocmd("VimEnter", {
  callback = connect_to_godot_server,
  desc = "Auto-connect to Godot server if project.godot exists"
})

-- Optional: Also check when changing directories
vim.api.nvim_create_autocmd("DirChanged", {
  callback = connect_to_godot_server,
  desc = "Auto-connect to Godot server when changing to Godot project directory"
})

-- Optional: Command to manually connect
vim.api.nvim_create_user_command("GodotConnect", connect_to_godot_server, {
  desc = "Manually connect to Godot server"
})
