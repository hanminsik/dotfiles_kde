---Launch a dialog for opening files or URLs (KDialog)
---@author ObserverOfTime
---@license 0BSD

local utils = require 'mp.utils'

local xorg = os.getenv('XDG_SESSION_TYPE') == 'x11'

-- 마지막 폴더 경로를 저장할 캐시 파일 경로 (XDG 규격 반영)
local cache_dir_file = (os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")) .. "/mpv/kdialog_last_dir"

local function get_last_dir()
local f = io.open(cache_dir_file, "r")
if f then
    local dir = f:read("*all")
    f:close()
    if dir and dir ~= "" then
        return (dir:gsub("^%s*(.-)%s*$", "%1"))
        end
        end
        return nil
        end

        local function save_last_dir(dir)
        local cache_dir = (os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")) .. "/mpv"
        os.execute("mkdir -p " .. string.format("%q", cache_dir))
        local f = io.open(cache_dir_file, "w")
        if f then
            f:write(dir)
            f:close()
            end
            end

            local MULTIMEDIA = table.concat({
                '*.aac',
                '*.avi',
                '*.flac',
                '*.flv',
                '*.m3u',
                '*.m3u8',
                '*.m4v',
                '*.mkv',
                '*.mov',
                '*.mp3',
                '*.mp4',
                '*.mpeg',
                '*.mpg',
                '*.oga',
                '*.ogg',
                '*.ogv',
                '*.opus',
                '*.wav',
                '*.webm',
                '*.wmv',
            }, ' ')

            local SUBTITLES = table.concat({
                '*.ass',
                '*.srt',
                '*.ssa',
                '*.sub',
                '*.txt',
            }, ' ')

            local ICON = 'mpv'

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
                local path = mp.get_property('path')
                if path then
                    path = utils.split_path(utils.join_path(utils.getcwd(), path))
                    save_last_dir(path)
                    default_arg = path
                    else
                        -- 재생 중인 파일이 없으면 저장된 마지막 폴더를 불러옴
                        default_arg = get_last_dir() or utils.getcwd()
                        end
                        end

                        local args = {
                            'kdialog', default_arg,
                            '--title', opts.title,
                            '--icon', ICON,
                            '--multiple', '--separate-output',
                            opts.type or '--getopenfilename', opts.text,
                        }
                        local ontop = mp.get_property_native('ontop')
                        if xorg then
                            local focus = utils.subprocess {
                                args = {'xdotool', 'getwindowfocus'}
                            }.stdout:gsub('\n$', '')
                            table.insert(args, 5, '--attach')
                            table.insert(args, 6, focus)
                            end
                            mp.set_property_native('ontop', false)
                            local kdialog = utils.subprocess {
                                args = args, cancellable = false
                            }
                            mp.set_property_native('ontop', ontop)
                            if kdialog.status ~= 0 then return end

                                local first = true
                                for file in kdialog.stdout:gmatch('[^\n]+') do
                                    local arg2 = opts.args[2]
                                    if opts.args[1] == 'loadfile' and not first then
                                        arg2 = 'append'
                                        end
                                        mp.commandv(opts.args[1], file, arg2)
                                        first = false
                                        end

                                        -- 파일이나 URL을 열었을 때 창을 최대화 (전체화면 아님)
                                        if opts.args[1] == 'loadfile' then
                                            mp.set_property_native('window-maximized', true)
                                            end
                                            end
                                            end

                                            mp.add_key_binding('Ctrl+f', 'open-files', KDialog {
                                                title = 'Select Files',
                                                text = 'Multimedia Files ('..MULTIMEDIA..')',
                                                               args = {'loadfile', 'replace'},
                                            })
                                            mp.add_key_binding('Ctrl+F', 'open-url', KDialog {
                                                title = 'Open URL',
                                                text = 'Enter the URL to open:',
                                                default = '',
                                                type = '--inputbox',
                                                args = {'loadfile', 'replace'},
                                            })
                                            mp.add_key_binding('Alt+f', 'open-subs', KDialog {
                                                title = 'Select Subs',
                                                text = 'Subtitle Files ('..SUBTITLES..')',
                                                               args = {'sub-add', 'select'},
                                            })
