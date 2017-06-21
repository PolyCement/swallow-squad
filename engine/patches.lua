-- monkey patches, maybe someday i'll make em into real utility functions

-- add something resembling python's startswith
function string.starts(str, sub_str)
   return string.sub(str, 1, string.len(sub_str)) == sub_str
end

-- add a split function
function string.split(str, delimiter)
    local delimiter, fields = delimiter or ",", {}
    local pattern = "([^" .. delimiter.. "]+)"
    string.gsub(str, pattern, function(x) table.insert(fields, x) end)
    return fields
end

-- i can't believe i have to define this myself
function table.length(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end
