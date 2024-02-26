--============ Copyright (c) Valve Corporation, All rights reserved. ==========
--
--
--=============================================================================

Msg( "Initializing script VM...\n" )


-------------------------------------------------------------------------------


-- returns a string like "foo.nut:53"
-- with the source file and line number of its caller.
-- returns the empty string if it couldn't get the source file and line number of its caller.
function _sourceline() 
    local v = debug.getinfo(2, "sl")
    if v then 
        return tostring(v.source) .. ":" .. tostring(v.currentline) .. " "
    else 
        return ""
    end
end

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------
require "utils.class"
require "utils.library"
require "utils.vscriptinit"
require "core.coreinit"
require "utils.utilsinit"
require "framework.frameworkinit"
require "framework.entities.entitiesinit"
require "game.gameinit"

function DumpScriptBindings()
	function BuildFunctionSignatureString( fnName, fdesc )
		local docList = {}
		table.insert( docList, string.format( "---[[ %s  %s ]]", fnName, fdesc.desc ) )
		table.insert( docList, string.format( "-- @return %s", fdesc.returnType ) )
		local parameterList = {}
		for i = 0, #fdesc-1 do
			local prmType, prmName = unpack( fdesc[i] )
			if prmName == nil or prmName == "" then prmName = string.format( "%s_%d", prmType, i+1 ) end
			table.insert( docList, string.format( "-- @param %s %s", prmName, prmType ) )
			table.insert( parameterList, prmName )
		end
		return string.format( "%s\nfunction %s( %s ) end\n", table.concat( docList, "\n"), fnName, table.concat( parameterList, ", " ) )
	end
	function SortedKeys( tbl )
		local result = {}
		if tbl ~= nil then
			for k,_ in pairs( tbl ) do table.insert( result, k ) end
		end
		table.sort( result )
		return result
	end
	for _,fnName in ipairs( SortedKeys( FDesc ) ) do
		local fdesc = FDesc[ fnName ]
		print( BuildFunctionSignatureString( fnName, fdesc ) )
	end
	for _,enumName in ipairs( SortedKeys( EDesc ) ) do
		local edesc = EDesc[ enumName ]
		print( string.format( "\n--- Enum %s", enumName ) )
		for _,valueName in ipairs( SortedKeys( edesc ) ) do
			if edesc[valueName] ~= "" then
				print( string.format( "%s = %d -- %s", valueName, _G[valueName], edesc[valueName] ) )
			else
				print( string.format( "%s = %d", valueName, _G[valueName] ) )
			end
		end
	end
	for _,className in ipairs( SortedKeys( CDesc ) ) do
		local cdesc = CDesc[ className ]
		for _,fnName in ipairs( SortedKeys( cdesc.FDesc ) ) do
			local fdesc = cdesc.FDesc[ fnName ]
			print( BuildFunctionSignatureString( string.format( "%s:%s", className, fnName ), fdesc ) )
		end
	end
end

function ScriptFunctionHelp( scope )
	if FDesc == nil or CDesc == nil then
		print( "Script help is only available in developer mode." )
		return
	end
	function SortedKeys( tbl )
		local result = {}
		if tbl ~= nil then
			for k,_ in pairs( tbl ) do table.insert( result, k ) end
		end
		table.sort( result )
		return result
	end
	function PrintEnum( enumName, enumTable )
		print( "\n***** Enum " .. tostring( enumName ) .. " *****" )
		for _,name in ipairs( SortedKeys( enumTable ) ) do
			print ( string.format( "%s (%d) %s", tostring( name ), _G[name], tostring( enumTable[name] ) ) )
		end
	end
	function PrintBindings( tbl )
		for _,name in ipairs( SortedKeys( tbl.FDesc ) ) do
			print( tostring( tbl.FDesc[name] ) )
		end
		for _,name in ipairs( SortedKeys( tbl.EDesc ) ) do
			PrintEnum( name, tbl.EDesc[name ] )
		end
	end

	if scope and scope ~= "" then
		if scope == "dump" then
			DumpScriptBindings()
		elseif scope == "global" then
			PrintBindings( _G )
		elseif scope == "all" then
			print( "***** Global Scope *****" )
			ScriptFunctionHelp( "global" )
			for _,className in ipairs( SortedKeys( CDesc ) ) do
				print( string.format( "\n***** Class %s ******", className ) )
				ScriptFunctionHelp( className )
			end
		elseif CDesc[scope] then
			print( string.format( "**** Class %s *****", scope ) )
			PrintBindings( CDesc[ scope ] )
		elseif EDesc[scope] then
			PrintEnum( scope, EDesc[scope] )
		else
			print( "Unable to find scope: " .. scope )
		end
	else
		print( "Usage: \"script_help <scope>\" where <scope> is one of the following:\n\tall\tglobal\tdump" )
		for _,className in ipairs( SortedKeys( CDesc ) ) do
			print( "\t" .. className )
		end
		for _,enumName in ipairs( SortedKeys( EDesc ) ) do
			print( "\t" .. enumName )
		end
	end
end

function GetFunctionSignature( func, name )
	local signature = name .. "( "
	local nParams = debug.getinfo( func ).nparams
	for i = 1, nParams do
		signature = signature .. debug.getlocal( func, i )
		if i ~= nParams then
			signature = signature .. ", "
		end
	end
	signature = signature .. " )"
	return signature
end

-- _PublishedHelp 是一个空表，用于存储已发布的帮助信息。
_PublishedHelp = {}

-- 这个函数用于将作用域表中的函数添加到脚本帮助信息中。
function AddToScriptHelp(scopeTable)
    -- 如果 FDesc 为 nil，则返回，不执行任何操作。
    if FDesc == nil then
        return
    end

    -- 遍历作用域表中的每个键值对。
    for name, val in pairs(scopeTable) do
        -- 如果值的类型为函数，则执行以下操作。
        if type(val) == "function" then
            -- 构建帮助字符串的键。
            local helpstr = "scripthelp_" .. name
            -- 检查作用域表中是否包含帮助字符串的键，并且 _PublishedHelp 中还未包含该键对应的信息。
            if vlua.contains(scopeTable, helpstr) and (not vlua.contains(_PublishedHelp, helpstr)) then
                -- 获取函数签名和名称，并将其与帮助信息一起存储到 FDesc 表中。
                FDesc[name] = GetFunctionSignature(val, name) .. "\n" .. scopeTable[helpstr]
                -- 将帮助字符串的键添加到 _PublishedHelp 表中，并将其值设置为 true，表示已发布。
                _PublishedHelp[helpstr] = true
            end
        end
    end
end

-- 这段代码在重新加载脚本时强制重新加载所有模块。
-- 如果 g_reloadState 为 nil，则初始化为一个空表，并将所有已加载的模块存储在其中。
if g_reloadState == nil then
    g_reloadState = {}
    -- 遍历 package.loaded 表中的所有键值对。
    for k, v in pairs(package.loaded) do
        -- 将当前模块的键值对存储到 g_reloadState 表中。
        g_reloadState[k] = v
    end
-- 否则，遍历所有已加载的模块。
else
    -- 再次遍历 package.loaded 表中的所有键值对。
    for k, v in pairs(package.loaded) do
        -- 如果 g_reloadState 表中没有当前模块的对应键值对，则说明该模块是新加载的。
        if g_reloadState[k] == nil then
            -- 将该模块从 package.loaded 中移除，以便在重新加载时强制重新加载。
            package.loaded[k] = nil
        end
    end
end

-- 此函数允许 Lua 实例扩展 C++ 实例的功能。
function ExtendInstance(instance, luaClass)
    -- 假设如果 BaseClass 已经设置，我们处于脚本重新加载的情况。
    -- 如果实例的元表 __index 不等于 luaClass，则重新绑定。
    if instance.BaseClass ~= nil and getmetatable(instance).__index ~= luaClass then
        -- 将 luaClass 的元表设置为其 __index 指向 instance.BaseClass。
        setmetatable(luaClass, { __index = instance.BaseClass })
        -- 将实例的元表设置为其 __index 指向 luaClass。
        setmetatable(instance, { __index = luaClass })
        -- 返回修改后的实例。
        return instance
    end
    -- 将当前元表的 __index 存储在 instance.BaseClass 中。
    instance.BaseClass = getmetatable(instance).__index
    -- 将 luaClass 的元表设置为与实例的元表相同。
    setmetatable(luaClass, getmetatable(instance))
    -- 将实例的元表设置为其 __index 指向 luaClass。
    setmetatable(instance, { __index = luaClass })
    -- 返回修改后的实例。
    return instance
end

Msg( "...done\n" )

-- 这段代码实现了以下功能：

-- 1. 初始化脚本虚拟机。
-- 2. 提供了获取调用者源文件和行号的函数。
-- 3. 加载了多个Lua模块，用于初始化脚本环境。
-- 4. 提供了DumpScriptBindings函数，用于打印脚本绑定的函数签名和枚举值。
-- 5. 提供了ScriptFunctionHelp函数，用于输出脚本函数的帮助文档。
-- 6. 实现了获取函数签名的函数。
-- 7. 实现了将脚本函数添加到帮助文档中的函数。
-- 8. 实现了重新加载模块的功能。
-- 9. 提供了ExtendInstance函数，用于让一个Lua实例扩展一个C++实例的功能。

-- 这段代码主要用于管理脚本环境，包括模块加载、帮助文档输出和模块重新加载等功能。