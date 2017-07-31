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

-- returns the number of elements in a table, regardless of indexing
function table.length(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- round towards 0
function math.round(x)
    return x > 0 and math.floor(x) or math.ceil(x)
end
