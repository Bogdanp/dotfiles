-- Paste snippets kept in the current repository.
--
-- Snippets are plain text files under <repo>/.snippets/. The "snippet"
-- action looks up the focused terminal's directory, finds the git repository
-- it belongs to, and opens an fzf picker in a split below it. The chosen file
-- is pasted into the terminal the action was run from.

local terminal = "com.superlogical.terminal"
local config_dir = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/rex"

-- Returns the path the terminal last reported as its working directory.
local function block_pwd(block_id)
  local r, err = rex.block.call(terminal, "pwd", { block_id = block_id })
  if r == nil then return nil, err end
  -- The server reports a URL such as file://host/Users/me/repo.
  local path = r.pwd and r.pwd:match("^file://[^/]*(/.*)$")
  if path == nil then return nil, "the terminal has not reported a working directory" end
  return path
end

local function repo_root(dir)
  local r, err = rex.exec({ "git", "rev-parse", "--show-toplevel" }, { cwd = dir, timeout = 5 })
  if r == nil then return nil, err end
  if not r.ok then return nil, dir .. " is not inside a git repository" end
  return (r.stdout:gsub("\n$", ""))
end

local function has_snippets(dir)
  local r = rex.exec({ "ls", "-1", dir }, { timeout = 5 })
  return r ~= nil and r.ok and r.stdout ~= ""
end

rex.action{
  name = "snippet",
  title = "Paste Snippet…",
  category = "Snippets",
  keywords = "snippets paste",
  description = "Pick a file from the repository's .snippets/ and paste it into the focused terminal.",
  run = function(ctx)
    if ctx.block_id == nil then error("no focused terminal", 0) end
    local pwd, err = block_pwd(ctx.block_id)
    if pwd == nil then error(err, 0) end
    local root, err = repo_root(pwd)
    if root == nil then error(err, 0) end
    local dir = root .. "/.snippets"
    if not has_snippets(dir) then error("no snippets in " .. dir, 0) end

    local _, err = rex.session.new_split{
      anchor_id = ctx.block_id,
      direction = "vertical",
      side = "after",
      ratio = 0.6,
      focus = true,
      layout = rex.layout.block{
        flavor = terminal .. ".shell",
        label = "Snippets",
        options = {
          cwd = dir,
          command = { config_dir .. "/snippet-pick", ctx.session_id, ctx.block_id, dir },
        },
      },
    }
    if err ~= nil then error(err, 0) end
  end,
}
