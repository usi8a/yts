local json = require('dkjson')
local http = require('socket.http')
local ltn12 = require('ltn12')

local function fetch_url(url)
    local response = {}
    local _, status = http.request{
        url = url,
        sink = ltn12.sink.table(response)
    }
    return table.concat(response), status
end

local function get_streams(movie_id)
    local streams = {}
    
    -- Check if it's a YTS ID (starts with 'yt')
    if string.sub(movie_id, 1, 2) == "yt" then
        local yts_id = string.sub(movie_id, 3)
        local url = "https://yts.mx/api/v2/movie_details.json?movie_id=" .. yts_id
        local body, status = fetch_url(url)
        
        if status == 200 then
            local data = json.decode(body)
            if data and data.data and data.data.movie and data.data.movie.torrents then
                for _, torrent in ipairs(data.data.movie.torrents) do
                    table.insert(streams, {
                        name = "YTS " .. torrent.quality,
                        title = torrent.quality .. " (" .. torrent.size .. ")",
                        infoHash = torrent.hash,
                        fileIdx = 0,
                        sources = {"torrent"},
                        behaviorHints = {
                            bingeGroup = "YTS-" .. yts_id
                        }
                    })
                end
            end
        end
    end
    
    return streams
end

local function handle_stream_request(args)
    local movie_id = args.id
    local streams = get_streams(movie_id)
    return { streams = streams }
end

return {
    handle_stream_request = handle_stream_request
}
