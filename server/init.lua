sure.getModule('esx')
sure.getModule('cooldown')
sure.getModule('db')

local resourceName = GetCurrentResourceName()
local doctorCommand = resourceName .. ':doctor'
local log = sure.getModule('log')

local function emit(message)
  if log ~= nil then
    log.info(message)
    return
  end

  lib.print.info(message)
end

--- @return { name: string, ok: boolean, detail: string }[]
local function diagnose()
  local checks = {}

  local function record(name, ok, detail)
    checks[#checks + 1] = { name = name, ok = ok, detail = detail }
  end

  local function resourceState(resource)
    local state = GetResourceState(resource)
    return state == 'started' or state == 'starting'
  end

  record('ox_lib started', resourceState('ox_lib'), 'GetResourceState(ox_lib)')
  record('es_extended started', resourceState('es_extended'), 'GetResourceState(es_extended)')
  record('oxmysql started', resourceState('oxmysql'), 'GetResourceState(oxmysql)')

  record('lib.print available', type(lib) == 'table' and type(lib.print) == 'table', 'lib.print.{info,error}')
  record('lib.callback available', type(lib) == 'table' and type(lib.callback) == 'table', 'lib.callback')
  record('lib.timer available', type(lib) == 'table' and type(lib.timer) == 'function', 'lib.timer')

  local oxlibResource = 'ox_lib'
  local oxlibVersion = GetResourceMetadata(oxlibResource, 'version', 0)
  record('ox_lib version reported', oxlibVersion ~= nil, tostring(oxlibVersion or 'unknown'))

  return checks
end

RegisterCommand(doctorCommand, function(source)
  if source ~= 0 then
    lib.print.error('[sure_lib][doctor] doctor command is console-only')
    return
  end

  emit('[sure_lib][doctor] running diagnostics...')

  local failures = 0
  for _, check in ipairs(diagnose()) do
    local marker = check.ok and 'OK ' or 'FAIL'
    emit(('[sure_lib][doctor] %s | %s (%s)'):format(marker, check.name, check.detail))
    if not check.ok then
      failures = failures + 1
    end
  end

  if failures == 0 then
    emit('[sure_lib][doctor] all checks passed')
  else
    emit(('[sure_lib][doctor] %d check(s) failed'):format(failures))
  end
end, true)
