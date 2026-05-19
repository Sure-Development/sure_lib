local h = RuntimeTest
local configPath = '@sure_lib_runtime_tests.config.runtime'

local function testPlayerHelpers()
  h.assertEqual('table', type(sure.player))
  h.assertPresent(sure.player.ped, 'sure.player.ped should be available')
  h.assertPresent(sure.player.coords, 'sure.player.coords should be available')
  h.assertPresent(sure.player.health, 'sure.player.health should be available')
end

local function testConfigLoad()
  local config = sure.getModule('config')
  local validator = sure.getModule('validator')
  local schema = validator.object({
    enabled = validator.boolean().required(),
    name = validator.string().required(),
    retryCount = validator.integer().min(0),
  })

  local value = config:reload(configPath, schema)

  h.assertTrue(value.enabled)
  h.assertEqual('sure_lib_runtime_tests', value.name)
end

local function testSpawnScopeCleanup()
  local spawn = sure.getModule('spawn')
  local scope = spawn:scope()
  local coords = GetEntityCoords(PlayerPedId())
  local object = scope:object('prop_beachflag_le', {
    x = coords.x + 1.0,
    y = coords.y,
    z = coords.z - 1.0,
  }, {
    alpha = 0,
    collision = false,
    freeze = true,
  })

  h.assertPresent(object, 'spawn:object should return an entity handle')
  h.assertTrue(DoesEntityExist(object), 'spawned object should exist before cleanup')

  scope:deleteAll()
  Wait(0)

  h.assertEqual(false, DoesEntityExist(object), 'scope:deleteAll should delete spawned objects')
end

local function testLuiPage()
  local lui = sure.getModule('lui')
  local track = sure.getModule('track')
  local count, setCount = track.state('runtimeCount', 0)
  local message, setMessage = track.state('runtimeMessage', 'Lua-driven UI without writing HTML')
  local tone, setTone = track.state('runtimeTone', 'success')
  local notices, setNotices = track.state('runtimeNotices', {})

  local increment = function(value)
    return value + 1
  end

  local function pushNotice(message)
    local id = tostring(GetGameTimer())

    setNotices(function(items)
      items[#items + 1] = {
        id = id,
        message = message,
      }

      return items
    end)
  end

  local function removeNotice(noticeId)
    setNotices(function(items)
      local nextItems = {}

      for _, item in ipairs(items) do
        if item.id ~= noticeId then
          nextItems[#nextItems + 1] = item
        end
      end

      return nextItems
    end)
  end

  lui.page('runtime', function(ui)
    ui.motionDiv({
      animate = {
        opacity = 1,
        y = 0,
      },
      className = 'fixed inset-0 overflow-auto p-6',
      initial = {
        opacity = 0,
        y = 10,
      },
      transition = {
        duration = 0.18,
        ease = 'easeOut',
      },
    }, function()
      ui.stack({
        className = 'w-[980px]',
        gap = 'lg',
      }, function()
        ui.panel({
          className = 'm-0 w-full max-w-[980px]',
          width = 'lg',
        }, function()
          ui.row({
            className = 'justify-between',
          }, function()
            ui.stack({
              gap = 'sm',
            }, function()
              ui.row(function()
                ui.badge('LUI Showcase', {
                  iconComponent = 'lucide:panels-top-left',
                  variant = 'secondary',
                })
                ui.badge('No Radix', {
                  iconComponent = 'lucide:box',
                  variant = 'outline',
                })
                ui.badge(tone, {
                  icon = tone() == 'error' and '!' or {
                    name = 'lucide:sparkles',
                    width = 12,
                  },
                  variant = tone() == 'error' and 'destructive' or 'default',
                })
              end)
              ui.typography('sure_lib Lua UI', {
                variant = 'h1',
              })
              ui.typography('A runtime test page that exercises every bundled LUI component from Lua.', {
                variant = 'lead',
              })
            end)

            ui.motionButton('Close', function()
              lui.close('runtime')
            end, {
              classBase = 'rounded-md bg-lui-accent px-4 py-2 text-sm font-semibold text-lui-accentForeground shadow-lui',
              endIconComponent = 'lucide:x',
              whileTap = {
                scale = 0.96,
              },
            })
          end)
        end)

        ui.row({
          align = 'start',
          className = 'items-start',
        }, function()
          ui.panel({
            className = 'm-0 w-[480px] max-w-[480px]',
            width = 'lg',
          }, function()
            ui.stack(function()
              ui.typography('Controls', {
                variant = 'h3',
              })
              ui.alert({
                description = 'Change values here and the tracked state updates the preview, table and notifications.',
                iconComponent = 'lucide:info',
                title = 'Interactive State',
              })
              ui.input({
                prefixIconComponent = 'lucide:message-square-text',
                onChange = function(payload)
                  setMessage(payload.value)
                end,
                placeholder = 'Type a short message',
                value = message,
              })
              ui.textarea({
                className = 'min-h-[96px]',
                onChange = function(payload)
                  setMessage(payload.value)
                end,
                placeholder = 'Long form text',
                value = message,
              })
              ui.select({
                closedIconComponent = 'lucide:chevron-down',
                onChange = function(payload)
                  setTone(payload.value)
                end,
                openIconComponent = 'lucide:chevron-up',
                options = {
                  {
                    label = 'Success',
                    value = 'success',
                  },
                  {
                    label = 'Warning',
                    value = 'warning',
                  },
                  {
                    label = 'Error',
                    value = 'error',
                  },
                },
                value = tone,
              })
              ui.slider({
                max = 12,
                min = 0,
                onChange = function(payload)
                  setCount(payload.value)
                end,
                rangeIconComponent = 'lucide:minus',
                thumbIcon = {
                  name = 'lucide:circle',
                  width = 10,
                },
                value = count,
              })
              ui.row(function()
                ui.button('Increment', function()
                  setCount(increment)
                end, {
                  iconComponent = 'lucide:plus',
                })
                ui.button('Notify', function()
                  pushNotice(message())
                end, {
                  iconComponent = 'lucide:bell',
                  variant = 'ghost',
                })
                ui.tooltip({
                  content = 'This tooltip is rendered by LUI without Radix.',
                  trigger = 'Hover hint',
                })
              end)
            end)
          end)

          ui.panel({
            className = 'm-0 w-[480px] max-w-[480px]',
            width = 'lg',
          }, function()
            ui.stack(function()
              ui.typography('Content', {
                variant = 'h3',
              })
              ui.tabs({
                {
                  content = 'Tabs, table, carousel, accordion, typography, badges, alerts, controls, motion and tooltip all come from Lua nodes.',
                  label = 'Overview',
                  value = 'overview',
                },
                {
                  content = 'Runtime utility styles support fractions like w-1/2 and arbitrary values like w-[50px].',
                  label = 'Styling',
                  value = 'styling',
                },
              })
              ui.carousel({
                {
                  description = 'Build UI by describing nodes in Lua.',
                  title = 'Lua first',
                },
                {
                  description = 'AnimatePresence powers enter and exit transitions.',
                  title = 'Motion ready',
                },
                {
                  description = 'Default colors follow a shadcn-like black and white palette.',
                  title = 'Clean defaults',
                },
              })
              ui.accordion({
                {
                  content = 'Use sure.getModule("lui") and build pages with the ui builder.',
                  title = 'How is this page made?',
                  value = 'how',
                },
                {
                  content = 'The renderer is bundled in sure_lib and resources only send Lua node trees.',
                  title = 'Where is the HTML?',
                  value = 'html',
                },
              }, {
                closedIconComponent = 'lucide:plus',
                openIconComponent = 'lucide:minus',
              })
            end)
          end)
        end)

        ui.panel({
          className = 'm-0 w-full max-w-[980px]',
          width = 'lg',
        }, function()
          ui.stack(function()
            ui.row({
              className = 'justify-between',
            }, function()
              ui.typography('Live Data', {
                variant = 'h3',
              })
              ui.badge('count: ' .. tostring(count()), {
                iconComponent = 'lucide:activity',
                variant = tone() == 'error' and 'destructive' or 'secondary',
              })
            end)
            ui.table({
              {
                key = 'component',
                label = 'Component',
              },
              {
                key = 'status',
                label = 'Status',
              },
              {
                key = 'note',
                label = 'Note',
              },
            }, {
              {
                component = 'Controls',
                note = 'input, select, textarea, slider, button',
                status = 'interactive',
              },
              {
                component = 'Display',
                note = 'alert, badge, table, typography',
                status = 'ready',
              },
              {
                component = 'Motion',
                note = 'presence, motionDiv, motionButton',
                status = 'animated',
              },
            })
          end)
        end)

        ui.panel({
          className = 'm-0 w-full max-w-[980px]',
          width = 'lg',
        }, function()
          ui.stack(function()
            ui.typography('Preview', {
              variant = 'h3',
            })
            ui.motionDiv({
              animate = {
                opacity = 1,
                scale = 1,
              },
              className = 'rounded-lg border border-lui-line bg-lui-panel-soft p-5',
              initial = {
                opacity = 0,
                scale = 0.98,
              },
              transition = {
                duration = 0.2,
              },
            }, function()
              ui.stack({
                gap = 'sm',
              }, function()
                ui.typography(message, {
                  variant = 'large',
                })
                ui.typography('Tone: ' .. tone() .. ' - Count: ' .. tostring(count()), {
                  variant = 'muted',
                })
              end)
            end)
          end)
        end)
      end)
    end)

    ui.motionStack({
      className = 'fixed right-6 top-6 z-50 w-80',
    }, function()
      ui.presence({
        initial = false,
        mode = 'popLayout',
      }, function()
        ui.foreach(notices, function(notice, _, itemUi)
          itemUi.motionDiv({
            animate = {
              opacity = 1,
              scale = 1,
              x = 0,
            },
            className = 'rounded-lg border border-lui-line bg-lui-panel px-4 py-3 shadow-lui',
            exit = {
              opacity = 0,
              scale = 0.96,
              x = 36,
            },
            initial = {
              opacity = 0,
              scale = 0.96,
              x = 36,
            },
            layout = true,
            transition = {
              duration = 0.2,
              ease = 'easeOut',
            },
          }, function()
            itemUi.stack({
              gap = 'sm',
            }, function()
              itemUi.row({
                className = 'justify-between',
              }, function()
                itemUi.badge('Notification', {
                  iconComponent = 'lucide:bell',
                  variant = 'secondary',
                })
                itemUi.motionButton('', function()
                  removeNotice(notice.id)
                end, {
                  classBase = 'rounded-md px-2 py-0.5 text-sm font-medium text-lui-muted',
                  iconComponent = 'lucide:x',
                  whileTap = {
                    scale = 0.9,
                  },
                })
              end)
              itemUi.text(notice.message, {
                className = 'font-medium',
              })
            end)
          end)
        end, {
          keyBy = 'id',
        })
      end)
    end)
  end)

  lui.open('runtime', {
    cursor = true,
    focus = true,
  })
  pushNotice('Runtime notification 1')
  pushNotice('Runtime notification 2')
  pushNotice('Runtime notification 3')
end

local clientTests = {
  {
    name = 'sure.player exposes runtime player helpers',
    fn = testPlayerHelpers,
  },
  {
    name = 'config loads on client through sure.config',
    fn = testConfigLoad,
  },
  {
    name = 'spawn scope creates and cleans up an object',
    fn = testSpawnScopeCleanup,
  },
  {
    name = 'lui renders a tracked runtime page',
    fn = testLuiPage,
  },
}

RegisterCommand('suretest:client', function()
  h.run('client', clientTests)
end, false)

RegisterNetEvent('sure_lib_runtime_tests:client:start', function()
  h.run('client', clientTests)
end)
