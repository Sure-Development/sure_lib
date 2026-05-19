local lui = {}

local state = require('@sure_lib.client.modules.lui.state')
local utils = require('@sure_lib.client.modules.lui.utils')
local track = sure.getModule('track')

local blueprint = require('@sure_lib.client.modules.lui.blueprint').create(lui, state, utils)
local builder = require('@sure_lib.client.modules.lui.builder').create(lui, state, utils, blueprint)
local renderer = require('@sure_lib.client.modules.lui.renderer').create(lui, state, utils, blueprint, builder, track)

blueprint.attach()
renderer.attach()
require('@sure_lib.client.modules.lui.nui').register(renderer)

return lui
