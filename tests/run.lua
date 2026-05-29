local harness = require('tests.support.harness')

local testFiles = {
  'tests.features.module_loader_test',
  'tests.features.validator_test',
  'tests.features.hook_test',
  'tests.features.slice_test',
  'tests.features.track_test',
  'tests.features.player_test',
  'tests.features.config_test',
  'tests.features.esx_server_test',
  'tests.features.db_test',
  'tests.features.cooldown_test',
  'tests.features.cooldown_by_id_test',
  'tests.features.spawn_test',
  'tests.features.lui_test',
  'tests.features.log_test',
  'tests.features.keybind_test',
  'tests.features.doctor_test',
}

for _, file in ipairs(testFiles) do
  require(file)
end

local failures = 0

for index, testCase in ipairs(harness.tests) do
  local ok, err = pcall(testCase.callback)
  if ok then
    print(('ok %d - %s'):format(index, testCase.name))
  else
    failures = failures + 1
    print(('not ok %d - %s'):format(index, testCase.name))
    print(('  %s'):format(tostring(err)))
  end
end

local total = #harness.tests
print(('%d/%d tests passed'):format(total - failures, total))

if failures > 0 then
  os.exit(1)
end
