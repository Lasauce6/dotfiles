return
{
	'andweeb/presence.nvim',
	config = function()
		require('presence'):setup({
			-- General options

			auto_update         = true,
			-- Text displayed when hovered over the Neovim image
			neovim_image_text   = "The One True Text Editor",
			-- Main image display (either "neovim" or "file")
			main_image          = "neovim",
			-- Use your own Discord application client id (not recommended)
			client_id           = "793271441293967371",
			-- Log messages level ("debug", "info", "warn", "error")
			log_level           = nil,
			-- Number of seconds to debounce events
			debounce_timeout    = 10,
			-- Displays the current line number instead of the current project
			enable_line_number  = false,
			-- A list of strings or Lua patterns that disable Rich Presence 
			-- if the current file name, path, or workspace matches
			blacklist           = {},
			show_time           = true,
			-- Decide which presence buttons you want to display (see "Button customization")
			buttons             = true,
			-- Format string rendered when an editable file is loaded in the buffer
			editing_text        = "Editing %s",
			-- Format string rendered when browsing a file file_explorer_text
			file_explorer_text  = "Browsing %s",
			-- Format string rendered when commiting changes in git
			git_commit_text     = "Committing changes",
			-- Format string rendered when managing plugins
			plugin_manager_text = "Managing plugins",
			-- Format string rendered when a read-only or unmodifiable file is loaded in the buffer
			reading_text        = "Reading %s",
			-- Workspace format string (either string or function(git_project_name: string|nil, buffer: string): string)
				workspace_text      = "Working on %s",
				-- Line number format string (for when enable_line_number is set to true)
				line_number_text    = "Line %s out of %s",
			})
		end,
	}
