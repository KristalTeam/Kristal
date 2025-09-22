print("BUILDING CUSTOM DOCS!")
print('ok?', ws and vm and guide and getDesc and getLabel and jsonb and util and markdown and true)

local old_makeDocObject_variable  = export.makeDocObject['variable']

local SIMPLE_TYPES = {
    boolean = true,
    integer = true,
    number = true,
    ["nil"] = true,
    string = true,
}
export.makeDocObject['variable'] = function(source, obj, has_seen)
    if old_makeDocObject_variable(source, obj, has_seen) == false then return false end
    if (obj.type == 'variable') then
        for i,pair in pairs(source:getSets(ws.rootUri)) do
            if(pair.type ~= 'setglobal') then
                goto CONTINUE
            end
            --print(obj.name, i)
            obj.defines[i].value = '???'
            if(SIMPLE_TYPES[pair.value.type]) then
                obj.defines[i].value = pair.value[1]
            elseif(pair.value.type == 'table') then
                local value = {}
                print(obj.name, i)
                
                for k,v in ipairs(pair.value) do
                    local index = v.field or v.index
                    index = index and index[1] or k
                    local comment = v.bindDocs and v.bindDocs[1].comment.text or nil
                    value[k] = type(v.value[1]) == 'table' and '<table>' or {
                        key = index,
                        value = v.value[1],
                        desc = comment
                    }
                end
                --for k,v in pairs(value) do print(k,v) end
                obj.defines[i].value = value
            elseif(pair.value.type == 'function') then
                obj.defines[i].value = 'idk lol is function'
            end
           --print()
            ::CONTINUE::
        end
    end
    
    if #obj.defines > 1 then

        local desc = ""
        local sets = 0
        local canonical_definition = 0

        for k, v in ipairs(obj.defines) do
            --pick larger description as canonical definition
            if ( string.len(v.desc or "") > string.len(desc) ) then
                canonical_definition = k
                desc = v.desc
            end
            if v.desc then
                sets = sets + 1
            end
        end
        if(canonical_definition ~= 0) then
            print("var assignment has more likely alternate definition, prioritizing it:")
            print(obj.name, desc, canonical_definition, obj.defines[canonical_definition])
            table.insert(obj.defines, 1,
                table.remove(obj.defines, canonical_definition)
            )
        end
    end
end

export.makeDocObject['type'] = function(source, obj, has_seen)
    if export.makeDocObject['variable'](source, obj, has_seen) == false then
        return false
    end
    
    obj.fields = {}
    vm.getSimpleClassFields(ws.rootUri, source, vm.ANY, function (next_source, mark, discardParentFields)
        if discardParentFields then return nil end

        if next_source.type == 'doc.field'
        or next_source.type == 'setfield'
        or next_source.type == 'setmethod'
        or next_source.type == 'tableindex'
        then
            table.insert(obj.fields, export.documentObject(next_source, has_seen))
        end
    end)
    table.sort(obj.fields, export.sortDoc)
end

export.serializeAndExport = function (docs, outputDir)
    local jsonPath = outputDir .. '/doc.json'

    --export to json
    local old_jsonb_supportSparseArray = jsonb.supportSparseArray
    jsonb.supportSparseArray = true
    local jsonOk, jsonErr = util.saveFile(jsonPath, jsonb.beautify(docs))
    jsonb.supportSparseArray = old_jsonb_supportSparseArray

    --error checking save file
    if( not (jsonOk) ) then
        return false, {jsonPath}, {jsonErr}
    end

    return true, {jsonPath}
end

local old_export_documentObject = export.documentObject
function export.documentObject(source, has_seen)
    if type(source) == 'table' and source.getSets then
        for _, set in ipairs(source:getSets(ws.rootUri)) do
            local ok, uri = pcall(guide.getUri, set)
            if not ok then
                return nil
            end
            --remove uri root (and prefix)
            local local_file_uri = uri
            local i, j = local_file_uri:find(DOC)
            if not j then
                return nil
            end
        end
    end
    local obj = old_export_documentObject(source, has_seen)
    if type(obj) == 'table' and obj.rawdesc then
        obj.rawdesc = nil
    end
    return obj
end