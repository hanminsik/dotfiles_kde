--[[
Launch a dialog for opening files or URLs (KDialog)
@author ObserverOfTime
@license 0BSD
]]

local utils = require 'mp.utils'

local xorg = os.getenv('XDG_SESSION_TYPE') == 'x11'

local cache_dir = (os.getenv('XDG_CACHE_HOME')
    or (os.getenv('HOME') .. '/.cache')) .. '/mpv'

local cache_dir_file = cache_dir .. '/kdialog_last_dir'

local ICON = 'mpv'

local MULTIMEDIA = table.concat({
    '*.aac', '*.avi', '*.flac', '*.flv',
    '*.m3u', '*.m3u8', '*.m4v', '*.mkv',
    '*.mov', '*.mp3', '*.mp4', '*.mpeg',
    '*.mpg', '*.oga', '*.ogg', '*.ogv',
    '*.opus', '*.wav', '*.webm', '*.wmv',
    '*.jpg', '*.jpeg', '*.png',
}, ' ')

-- Save the last opened directory.
local function save_last_dir(dir)
    if not dir or dir == '' then
        return
    end

    utils.subprocess({
        args = { 'mkdir', '-p', cache_dir },
    })

    local f, err = io.open(cache_dir_file, 'w')

    if not f then
        mp.msg.error('Failed to save last directory: ' .. tostring(err))
        return
    end

    f:write(dir)
    f:close()

    mp.msg.info('Last directory saved: ' .. dir)
end

-- Read the last opened directory.
local function get_last_dir()
    local f = io.open(cache_dir_file, 'r')

    if not f then
        return nil
    end

    local dir = f:read('*all')
    f:close()

    if dir then
        dir = dir:gsub('^%s*(.-)%s*$', '%1')
        if dir ~= '' then
            return dir
        end
    end

    return nil
end

-- Get the directory of the currently playing file.
local function get_current_dir()
    local path = mp.get_property('path')

    if not path or path == '' then
        return nil
    end

    -- Ignore URLs.
    if path:match('^%a[%w+.-]*://') then
        return nil
    end

    local working_dir = mp.get_property('working-directory')
        or utils.getcwd()

    local full_path = path

    -- Convert relative paths to absolute paths.
    if not path:match('^/') then
        full_path = utils.join_path(working_dir, path)
    end

    local dir = utils.split_path(full_path)

    return dir
end

-- Save the directory whenever a file is loaded.
mp.register_event('file-loaded', function()
    local dir = get_current_dir()

    if dir then
        save_last_dir(dir)
    end
end)

---@class KDOpts
---@field title string
---@field text string
---@field default? string
---@field type? string
---@field args string[]

---@param opts KDOpts
---@return fun()
local function KDialog(opts)
    return function()
        local default_arg = opts.default

        if not default_arg then
            local dir = get_current_dir()

            if dir then
                save_last_dir(dir)
                default_arg = dir
            else
                default_arg = get_last_dir() or utils.getcwd()
            end
        end

        local args = {
            'kdialog',
            default_arg,
            '--title', opts.title,
            '--icon', ICON,
            '--multiple',
            '--separate-output',
            opts.type or '--getopenfilename',
            opts.text,
        }

        local ontop = mp.get_property_native('ontop')

        if xorg then
            local focus = utils.subprocess({
                args = { 'xdotool', 'getwindowfocus' },
            })

            if focus.status == 0 and focus.stdout then
                table.insert(args, 5, '--attach')
                table.insert(args, 6, focus.stdout:gsub('\n$', ''))
            end
        end

        mp.set_property_native('ontop', false)

        local kdialog = utils.subprocess({
            args = args,
            cancellable = false,
        })

        mp.set_property_native('ontop', ontop)

        if kdialog.status ~= 0 then
            return
        end

        local first = true

        for file in kdialog.stdout:gmatch('[^\r\n]+') do
            local arg2 = opts.args[2]

            if opts.args[1] == 'loadfile' and not first then
                arg2 = 'append'
            end

            mp.commandv(opts.args[1], file, arg2)

            first = false
        end
    end
end

-- Open multimedia files.
mp.add_key_binding('Ctrl+f', 'open-files', KDialog({
    title = 'Please Select Files',
    text = 'Multimedia Files (' .. MULTIMEDIA .. ')',
    args = { 'loadfile', 'replace' },
}))
