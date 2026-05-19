RuntimeTest = RuntimeTest or {}

local function logInfo(message)
  lib.print.info('[sure_lib_runtime_tests] ' .. message)
end

local function logError(message)
  lib.print.error('[sure_lib_runtime_tests] ' .. message)
end

function RuntimeTest.assertEqual(expected, actual, message)
  if expected ~= actual then
    error((message or 'values are not equal') .. (': expected %s, got %s'):format(tostring(expected), tostring(actual)), 2)
  end
end

function RuntimeTest.assertTrue(value, message)
  RuntimeTest.assertEqual(true, value, message)
end

function RuntimeTest.assertNil(value, message)
  if value ~= nil then
    error((message or 'expected nil') .. (': got %s'):format(tostring(value)), 2)
  end
end

function RuntimeTest.assertPresent(value, message)
  if value == nil then
    error(message or 'expected value to be present', 2)
  end
end

function RuntimeTest.run(scopeName, tests)
  CreateThread(function()
    local failures = 0

    logInfo(('running %s tests (%d)'):format(scopeName, #tests))

    for index, testCase in ipairs(tests) do
      local ok, err = pcall(testCase.fn)
      if ok then
        logInfo(('ok %d - %s'):format(index, testCase.name))
      else
        failures = failures + 1
        logError(('not ok %d - %s'):format(index, testCase.name))
        logError(tostring(err))
      end
    end

    logInfo(('%s result: %d/%d passed'):format(scopeName, #tests - failures, #tests))
  end)
end
