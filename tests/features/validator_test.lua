local h = require('tests.support.harness')

h.test('validator parses primitive types and required fields', function()
  h.reset('shared')
  local validator = h.load('shared/modules/validator/index.lua')

  h.assertTrue(validator.string().required().parse('hello'))
  h.assertTrue(validator.number().parse(10))
  h.assertTrue(validator.boolean().parse(false))
  h.assertTrue(validator.callback().parse(function() end))
  h.assertErrorContains(function()
    validator.string().required().parse(nil)
  end, 'Required field is missing')
end)

h.test('validator parses nested objects and arrays', function()
  h.reset('shared')
  local validator = h.load('shared/modules/validator/index.lua')
  local schema = validator.object({
    items = validator.array(validator.object({
      name = validator.string().required(),
      count = validator.number().required(),
    })),
  })

  h.assertTrue(schema.parse({
    items = {
      { name = 'bread', count = 2 },
      { name = 'water', count = 1 },
    },
  }))
end)

h.test('validator rejects invalid nested values', function()
  h.reset('shared')
  local validator = h.load('shared/modules/validator/index.lua')
  local schema = validator.object({
    count = validator.number().required(),
  })

  h.assertErrorContains(function()
    schema.parse({ count = '2' })
  end, 'Expected type "number"')
end)

h.test('validator supports custom error messages', function()
  h.reset('shared')
  local validator = h.load('shared/modules/validator/index.lua')

  h.assertErrorContains(function()
    validator.string().required('Name is required').parse(nil)
  end, 'Name is required')

  h.assertErrorContains(function()
    validator.number().message('Amount must be numeric').parse('10')
  end, 'Amount must be numeric')
end)

h.test('validator supports integer and number ranges', function()
  h.reset('shared')
  local validator = h.load('shared/modules/validator/index.lua')

  h.assertTrue(validator.integer().parse(10))
  h.assertTrue(validator.number().min(1).max(5).parse(3))
  h.assertTrue(validator.number().between(1, 5).parse(5))

  h.assertErrorContains(function()
    validator.integer().parse(1.5)
  end, 'Expected integer')

  h.assertErrorContains(function()
    validator.number().min(3).parse(2)
  end, 'greater than or equal to 3')
end)

h.test('validator supports oneOf values', function()
  h.reset('shared')
  local validator = h.load('shared/modules/validator/index.lua')

  h.assertTrue(validator.string().oneOf({ 'police', 'ambulance' }).parse('police'))

  h.assertErrorContains(function()
    validator.string().oneOf({ 'police', 'ambulance' }).parse('mechanic')
  end, 'Expected one of')
end)
