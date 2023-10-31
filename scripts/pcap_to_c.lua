local padding = 5 -- 1 to go after the "/" and 4 for the "file" string
local output = {}
local max = -1

-- Iterate over each file in the current directory
for filename in io.popen('ls'):lines() do
    if filename:find(".pcap") then
        -- Open the file, read its content then close it
        local file = io.open(filename, "r")
        if file then
            local content = file:read("*a")
            file:close()

            -- find the number, and proceed to use it as an index for the output (where content is the value)
            local begin, finish = content:find("//")
            local number = tonumber(content:sub(finish + padding, content:len()))
            output[number] = content:sub(0, begin - 1)

            -- Update max to know the last line number
            max = math.max(max, number)
        else
            print("Couldn't open file: ", filename)
        end
    end
end

local filename = "main.c"
-- Write to main.c if any matching files were found
if next(output) ~= nil then 
    local file = io.open(filename, "w")
    if file then
        for i = 1, max do
            file:write(output[i])
        end
        file:close()
        print("Created file: ", filename)
    else
        print("Couldn't create file: ", filename)
    end
else
    print("No matching files")
end