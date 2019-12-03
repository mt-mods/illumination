illumination = {}
illumination.player_lights = {}

illumination.illumination_items = {} -- Non-node items to also illuminate
if minetest.get_modpath("mobs_monster") then
	illumination.illumination_items["mobs:lava_orb"] = 4
	illumination.illumination_items["mobs:pick_lava"] = 8
end
if minetest.get_modpath("lavastuff") then
	illumination.illumination_items["lavastuff:orb"] = 4
	illumination.illumination_items["lavastuff:sword"] = 8
	illumination.illumination_items["lavastuff:pick"] = 8
	illumination.illumination_items["lavastuff:axe"] = 8
	illumination.illumination_items["lavastuff:shovel"] = 8
end
if minetest.get_modpath("multitools") then
	illumination.illumination_items["multitools:multitool_lava"] = 14
end

local light_def = {
	drawtype = "airlike",
	paramtype = "light",
	groups = {not_in_creative_inventory = 1, not_blocking_trains = 1},
	sunlight_propagates = true,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	light_source = 4,
}

minetest.register_node("illumination:light_faint", light_def)
light_def.light_source = 8
minetest.register_node("illumination:light_dim", light_def)
light_def.light_source = 12
minetest.register_node("illumination:light_mid", light_def)
light_def.light_source = minetest.LIGHT_MAX
minetest.register_node("illumination:light_full", light_def)

local function round_pos(pos)
	local newpos = {}
	newpos.x = math.floor(pos.x + 0.5)
	newpos.y = math.floor(pos.y + 0.5)
	newpos.z = math.floor(pos.z + 0.5)
	return newpos
end

local function can_light(pos)
	local node_name = minetest.get_node(pos).name
	return (node_name == "air"
		or node_name == "illumination:light_faint"
		or node_name == "illumination:light_dim"
		or node_name == "illumination:light_mid"
		or node_name == "illumination:light_full")
end

local function remove_illumination(pos)
	if pos then
		if can_light(pos) then
			minetest.set_node(pos, {name = "air"})
		end
	end
end

minetest.register_abm({ --This should clean up nodes that don't get deleted for some reason
	nodenames = {
		"illumination:light_faint",
		"illumination:light_dim",
		"illumination:light_mid",
		"illumination:light_full"
	},
	interval = 2,
	chance = 10,
	action = function(pos)
		local can_exist = false
		for _, player in ipairs(minetest.get_connected_players()) do
			if illumination.player_lights[player:get_player_name()] then
				local light_pos = illumination.player_lights[player:get_player_name()].pos
				if light_pos then
					if vector.equals(pos, light_pos) then
						can_exist = true
					end
				end
			end
		end
		if not can_exist then
			remove_illumination(pos)
		end
	end
})

minetest.register_on_joinplayer(function(player)
	illumination.player_lights[player:get_player_name()] = {
		pos = round_pos(player:get_pos()),
		player_pos = round_pos(player:get_pos())
	}
end)

minetest.register_on_leaveplayer(function(player)
	local player_name = player:get_player_name()

	remove_illumination(illumination.player_lights[player_name].pos)

	local remaining_players = {}
	for _, online in ipairs(minetest.get_connected_players()) do
		if online:get_player_name() ~= player_name then
			remaining_players[online:get_player_name()] = illumination.player_lights[online:get_player_name()]
		end
	end
	illumination.player_lights = remaining_players
end)

minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do

		local player_name = player:get_player_name()

		if illumination.player_lights[player_name] then

			local pos = round_pos(player:get_pos())
			local old_pos = illumination.player_lights[player_name].pos
			local wielded_name = player:get_wielded_item():get_name()

			local light = 0
			if minetest.registered_nodes[wielded_name] then
				light = minetest.registered_nodes[wielded_name].light_source
			elseif illumination.illumination_items[wielded_name] then
				light = illumination.illumination_items[wielded_name]
			end

			if light <= 2 then
				remove_illumination(old_pos)
				illumination.player_lights[player_name].pos = nil
				return -- no illumination
			end

			local light_name = "illumination:light_faint"
			if light > 7 then
				light_name = "illumination:light_dim"
			end
			if light > 10 then
				light_name = "illumination:light_mid"
			end
			if light > 13 then
				light_name = "illumination:light_full"
			end

			if old_pos then
				if light_name == minetest.get_node(old_pos).name
					and vector.equals(pos, old_pos) then
					return -- has illumination
				end
			end
			illumination.player_lights[player_name].player_pos = pos

			if not can_light(pos) then
				if can_light({x=pos.x, y=pos.y+1, z=pos.z}) then
					pos = {x=pos.x, y=pos.y+1, z=pos.z}
				elseif can_light({x=pos.x, y=pos.y+2, z=pos.z}) then
					pos = {x=pos.x, y=pos.y+2, z=pos.z}
				elseif can_light({x=pos.x, y=pos.y-1, z=pos.z}) then
					pos = {x=pos.x, y=pos.y-1, z=pos.z}
				elseif can_light({x=pos.x+1, y=pos.y, z=pos.z}) then
					pos = {x=pos.x+1, y=pos.y, z=pos.z}
				elseif can_light({x=pos.x, y=pos.y, z=pos.z+1}) then
					pos = {x=pos.x, y=pos.y, z=pos.z+1}
				elseif can_light({x=pos.x-1, y=pos.y, z=pos.z}) then
					pos = {x=pos.x-1, y=pos.y, z=pos.z}
				elseif can_light({x=pos.x, y=pos.y, z=pos.z-1}) then
					pos = {x=pos.x, y=pos.y, z=pos.z-1}
				elseif can_light({x=pos.x+1, y=pos.y+1, z=pos.z}) then
					pos = {x=pos.x+1, y=pos.y+1, z=pos.z}
				elseif can_light({x=pos.x-1, y=pos.y+1, z=pos.z}) then
					pos = {x=pos.x-1, y=pos.y+1, z=pos.z}
				elseif can_light({x=pos.x, y=pos.y+1, z=pos.z+1}) then
					pos = {x=pos.x, y=pos.y+1, z=pos.z+1}
				elseif can_light({x=pos.x, y=pos.y+1, z=pos.z-1}) then
					pos = {x=pos.x, y=pos.y+1, z=pos.z-1}
				end
			end

			if can_light(pos) then -- add illumination
				illumination.player_lights[player_name].pos = pos
				minetest.set_node(pos, {name = light_name})
			end

			if old_pos then
				if not vector.equals(pos, old_pos) then -- remove old illumination
					remove_illumination(old_pos)
				end
			end
		end
	end
end)
