local h = require('tests.support.harness')

local function setupLui()
  local context = h.reset('client')
  require('@sure_lib.init')
  return sure.getModule('lui'), context
end

h.test('lui renders declarative pages to NUI messages', function()
  local lui, context = setupLui()

  lui.page('shop', function(ui)
    ui.stack(function()
      ui.text('Shop')
      ui.button('Buy', function() end)
    end)
  end)

  local message = context.nuiMessages[1]
  local stack = message.tree.children[1]

  h.assertEqual('lui:render', message.type)
  h.assertEqual('shop', message.page)
  h.assertEqual('stack', stack.type)
  h.assertEqual('text', stack.children[1].type)
  h.assertEqual('Shop', stack.children[1].props.value)
  h.assertEqual('button', stack.children[2].type)
  h.assertEqual('Buy', stack.children[2].props.label)
  h.assertEqual('string', type(stack.children[2].props.actionId))
end)

h.test('lui routes NUI events to Lua handlers', function()
  local lui, context = setupLui()
  local pressed = false

  lui.page('shop', function(ui)
    ui.button('Buy', function(payload)
      pressed = payload.item == 'water'
    end)
  end)

  local actionId = context.nuiMessages[1].tree.children[1].props.actionId
  context.nuiCallbacks['lui:event']({
    actionId = actionId,
    payload = {
      item = 'water',
    },
  }, function() end)

  h.assertTrue(pressed)
end)

h.test('lui renders hybrid declarative node trees', function()
  local lui, context = setupLui()

  local function Header(title)
    return lui.panel({
      className = 'header',
    }, {
      lui.text(title),
      lui.button('Close', function() end, {
        endIconComponent = 'lucide:x',
      }),
    })
  end

  lui.page(
    'hybrid',
    lui.stack({
      className = 'page',
    }, {
      Header('Dashboard'),
      lui.row({}, {
        lui.badge('Live', {
          iconComponent = 'lucide:activity',
        }),
        lui.typography('Ready', {
          variant = 'muted',
        }),
      }),
    })
  )

  local tree = context.nuiMessages[1].tree
  local stack = tree.children[1]
  local header = stack.children[1]
  local row = stack.children[2]

  h.assertEqual('stack', stack.type)
  h.assertEqual('page', stack.props.className)
  h.assertEqual('panel', header.type)
  h.assertEqual('Dashboard', header.children[1].props.value)
  h.assertEqual('Close', header.children[2].props.label)
  h.assertEqual('lucide:x', header.children[2].props.endIconComponent)
  h.assertEqual('string', type(header.children[2].props.actionId))
  h.assertEqual('row', row.type)
  h.assertEqual('Live', row.children[1].props.label)
  h.assertEqual('Ready', row.children[2].props.value)
end)

h.test('lui mixes callback builders with declarative children', function()
  local lui, context = setupLui()
  local pressed = false

  lui.page('mixed', function(ui)
    ui.stack({
      className = 'shell',
    }, {
      ui.node.text('Title'),
      ui.node.button('Save', function()
        pressed = true
      end),
    })
  end)

  local stack = context.nuiMessages[1].tree.children[1]
  local actionId = stack.children[2].props.actionId

  context.nuiCallbacks['lui:event']({
    actionId = actionId,
  }, function() end)

  h.assertEqual('shell', stack.props.className)
  h.assertEqual('Title', stack.children[1].props.value)
  h.assertEqual('Save', stack.children[2].props.label)
  h.assertTrue(pressed)
end)

h.test('lui declarative list tracks reactive arrays', function()
  local lui, context = setupLui()
  local track = sure.getModule('track')
  local items, setItems = track.state('hybridItems', { 'bread' })

  lui.page(
    'hybrid-list',
    lui.list(items, function(item, index)
      return lui.text(index .. ':' .. item)
    end)
  )

  setItems({ 'bread', 'water' })

  local firstList = context.nuiMessages[1].tree.children[1]
  local patch = context.nuiMessages[2].patches[1]
  local secondList = patch.node

  h.assertEqual('foreach', firstList.type)
  h.assertEqual('lui:patch', context.nuiMessages[2].type)
  h.assertEqual('replaceNode', patch.op)
  h.assertEqual(1, #firstList.children)
  h.assertEqual(2, #secondList.children)
  h.assertEqual('2:water', secondList.children[2].children[1].props.value)
end)

h.test('lui renders motion presence nodes with animation props', function()
  local lui, context = setupLui()

  lui.page('animated', function(ui)
    ui.presence({
      initial = false,
      mode = 'wait',
    }, function()
      ui.motionDiv({
        animate = {
          opacity = 1,
          y = 0,
        },
        exit = {
          opacity = 0,
          y = -8,
        },
        font = 'Inter, sans-serif',
        initial = {
          opacity = 0,
          y = 8,
        },
        transition = {
          duration = 0.2,
          ease = 'easeOut',
        },
      }, function()
        ui.text('Ready')
      end)
    end)
  end)

  local presence = context.nuiMessages[1].tree.children[1]
  local motion = presence.children[1]

  h.assertEqual('presence', presence.type)
  h.assertEqual(false, presence.props.initial)
  h.assertEqual('wait', presence.props.mode)
  h.assertEqual('motion', motion.type)
  h.assertEqual('div', motion.props.as)
  h.assertEqual(1, motion.props.animate.opacity)
  h.assertEqual(-8, motion.props.exit.y)
  h.assertEqual(0.2, motion.props.transition.duration)
  h.assertEqual('Inter, sans-serif', motion.props.font)
  h.assertEqual('Ready', motion.children[1].props.value)
end)

h.test('lui routes motion button events to Lua handlers', function()
  local lui, context = setupLui()
  local pressed = false

  lui.page('animated-actions', function(ui)
    ui.motionButton('Tap', function()
      pressed = true
    end, {
      whileTap = {
        scale = 0.95,
      },
    })
  end)

  local button = context.nuiMessages[1].tree.children[1]
  context.nuiCallbacks['lui:event']({
    actionId = button.props.actionId,
  }, function() end)

  h.assertEqual('motion', button.type)
  h.assertEqual('button', button.props.as)
  h.assertEqual('Tap', button.props.label)
  h.assertEqual(0.95, button.props.whileTap.scale)
  h.assertTrue(pressed)
end)

h.test('lui keeps theme and font props on the page tree', function()
  local lui, context = setupLui()

  lui.page('theme', function(ui)
    ui.panel({
      font = 'Prompt, sans-serif',
      theme = {
        accent = '#ffffff',
        panel = 'rgba(0, 0, 0, 0.42)',
      },
    }, function()
      ui.text('Theme')
    end)
  end, {
    font = 'Inter, sans-serif',
    theme = {
      ink = '#ffffff',
      muted = '#d4d4d8',
    },
  })

  local tree = context.nuiMessages[1].tree
  local panel = tree.children[1]

  h.assertEqual('Inter, sans-serif', tree.props.font)
  h.assertEqual('#ffffff', tree.props.theme.ink)
  h.assertEqual('Prompt, sans-serif', panel.props.font)
  h.assertEqual('rgba(0, 0, 0, 0.42)', panel.props.theme.panel)
end)

h.test('lui renders shadcn-like display component nodes', function()
  local lui, context = setupLui()

  lui.page('components', function(ui)
    ui.stack(function()
      ui.alert({
        description = 'Heads up',
        title = 'Alert',
      })
      ui.badge('Live', {
        variant = 'secondary',
      })
      ui.accordion({
        {
          content = 'Value',
          title = 'Item',
          value = 'item',
        },
      })
      ui.tabs({
        {
          content = 'Account content',
          label = 'Account',
          value = 'account',
        },
      })
      ui.table({ 'name', 'status' }, {
        {
          name = 'sure_lib',
          status = 'ready',
        },
      })
      ui.carousel({
        {
          description = 'First slide',
          title = 'Slide',
        },
      })
      ui.typography('Heading', {
        variant = 'h2',
      })
      ui.tooltip({
        content = 'Helpful text',
        trigger = 'Hover me',
      })
    end)
  end)

  local stack = context.nuiMessages[1].tree.children[1]

  h.assertEqual('alert', stack.children[1].type)
  h.assertEqual('Alert', stack.children[1].props.title)
  h.assertEqual('badge', stack.children[2].type)
  h.assertEqual('Live', stack.children[2].props.label)
  h.assertEqual('accordion', stack.children[3].type)
  h.assertEqual('Item', stack.children[3].props.items[1].title)
  h.assertEqual('tabs', stack.children[4].type)
  h.assertEqual('account', stack.children[4].props.tabs[1].value)
  h.assertEqual('table', stack.children[5].type)
  h.assertEqual('status', stack.children[5].props.columns[2])
  h.assertEqual('carousel', stack.children[6].type)
  h.assertEqual('Slide', stack.children[6].props.items[1].title)
  h.assertEqual('typography', stack.children[7].type)
  h.assertEqual('h2', stack.children[7].props.variant)
  h.assertEqual('tooltip', stack.children[8].type)
  h.assertEqual('Helpful text', stack.children[8].props.content)
end)

h.test('lui typography accepts tracked values as text content', function()
  local lui, context = setupLui()
  local track = sure.getModule('track')
  local title, setTitle = track.state('typographyTitle', 'First')

  lui.page('typography-state', function(ui)
    ui.typography(title, {
      variant = 'large',
    })
  end)

  setTitle('Second')

  h.assertEqual('First', context.nuiMessages[1].tree.children[1].props.value)
  h.assertEqual('lui:patch', context.nuiMessages[2].type)
  h.assertEqual('Second', context.nuiMessages[2].patches[1].props.value)
end)

h.test('lui routes textarea and slider changes to Lua handlers', function()
  local lui, context = setupLui()
  local textValue = nil
  local sliderValue = nil

  lui.page('form', function(ui)
    ui.textarea({
      onChange = function(payload)
        textValue = payload.value
      end,
      value = 'hello',
    })
    ui.slider({
      max = 10,
      onChange = function(payload)
        sliderValue = payload.value
      end,
      value = 3,
    })
  end)

  local textarea = context.nuiMessages[1].tree.children[1]
  local slider = context.nuiMessages[1].tree.children[2]

  context.nuiCallbacks['lui:event']({
    actionId = textarea.props.actionId,
    payload = {
      value = 'changed',
    },
  }, function() end)
  context.nuiCallbacks['lui:event']({
    actionId = slider.props.actionId,
    payload = {
      value = 7,
    },
  }, function() end)

  h.assertEqual('textarea', textarea.type)
  h.assertEqual('slider', slider.type)
  h.assertEqual('changed', textValue)
  h.assertEqual(7, sliderValue)
end)

h.test('lui preserves part class props for composed components', function()
  local lui, context = setupLui()

  lui.page('part-classes', function(ui)
    ui.select({
      activeOptionClassName = 'bg-[#111111] text-white',
      icon = 'chevron',
      optionActiveLabelClassName = 'font-bold',
      menuClassName = 'w-[260px]',
      optionClassName = 'px-4',
      options = { 'one', 'two' },
      triggerClassName = 'w-[240px]',
      value = 'one',
    })
    ui.tabs({
      {
        content = 'One',
        label = 'One',
        value = 'one',
      },
    }, {
      activeTriggerClassName = 'bg-[#111111] text-white',
      activeLabelClassName = 'font-bold',
      contentClassName = 'p-4',
      listClassName = 'border-[#111111]',
    })
    ui.slider({
      rangeIcon = '•',
      rangeClassName = 'bg-[#111111]',
      thumbIcon = 'x',
      thumbClassName = 'border-[#111111]',
      trackClassName = 'h-[6px]',
      value = 5,
    })
    ui.accordion({
      {
        content = 'Body',
        title = 'Title',
      },
    }, {
      closedIcon = '+',
      contentClassName = 'text-center',
      openIcon = '-',
      titleClassName = 'font-bold',
    })
  end)

  local tree = context.nuiMessages[1].tree

  h.assertEqual('w-[240px]', tree.children[1].props.triggerClassName)
  h.assertEqual('bg-[#111111] text-white', tree.children[1].props.activeOptionClassName)
  h.assertEqual('font-bold', tree.children[1].props.optionActiveLabelClassName)
  h.assertEqual('border-[#111111]', tree.children[2].props.listClassName)
  h.assertEqual('bg-[#111111]', tree.children[3].props.rangeClassName)
  h.assertEqual('x', tree.children[3].props.thumbIcon)
  h.assertEqual('-', tree.children[4].props.openIcon)
  h.assertEqual('font-bold', tree.children[4].props.titleClassName)
end)

h.test('lui preserves text and Iconify icon specs for renderer components', function()
  local lui, context = setupLui()

  lui.page('icons', function(ui)
    ui.stack(function()
      ui.button('Save', function() end, {
        endIcon = '->',
        icon = {
          name = 'lucide:save',
          width = 16,
        },
      })
      ui.badge('Ready', {
        iconComponent = 'lucide:check',
      })
      ui.alert({
        icon = {
          iconComponent = 'lucide:info',
          className = 'text-blue-500',
        },
        title = 'Heads up',
      })
      ui.input({
        prefixIconComponent = 'lucide:search',
        suffix = 'esc',
      })
      ui.select({
        closedIconComponent = 'lucide:chevron-down',
        openIconComponent = 'lucide:chevron-up',
        options = { 'one', 'two' },
        value = 'one',
      })
      ui.slider({
        rangeIconComponent = 'lucide:minus',
        thumbIcon = {
          name = 'lucide:circle',
          width = 10,
        },
        value = 5,
      })
      ui.accordion({
        {
          content = 'Body',
          title = 'Title',
        },
      }, {
        closedIconComponent = 'lucide:plus',
        openIconComponent = 'lucide:minus',
      })
      ui.motionButton('Close', function() end, {
        iconComponent = 'lucide:x',
      })
    end)
  end)

  local stack = context.nuiMessages[1].tree.children[1]

  h.assertEqual('lucide:save', stack.children[1].props.icon.name)
  h.assertEqual('->', stack.children[1].props.endIcon)
  h.assertEqual('lucide:check', stack.children[2].props.iconComponent)
  h.assertEqual('lucide:info', stack.children[3].props.icon.iconComponent)
  h.assertEqual('text-blue-500', stack.children[3].props.icon.className)
  h.assertEqual('lucide:search', stack.children[4].props.prefixIconComponent)
  h.assertEqual('lucide:chevron-up', stack.children[5].props.openIconComponent)
  h.assertEqual('lucide:circle', stack.children[6].props.thumbIcon.name)
  h.assertEqual('lucide:plus', stack.children[7].props.closedIconComponent)
  h.assertEqual('lucide:x', stack.children[8].props.iconComponent)
end)

h.test('lui supports Vue-like conditional rendering helpers', function()
  local lui, context = setupLui()
  local track = sure.getModule('track')
  local visible, setVisible = track.state('conditionalVisible', false)

  lui.page('conditional', function(ui)
    ui.when(visible, function(whenUi)
      whenUi.text('Visible')
    end, function(elseUi)
      elseUi.text('Hidden')
    end)
  end)

  setVisible(true)

  h.assertEqual('Hidden', context.nuiMessages[1].tree.children[1].props.value)
  h.assertEqual('lui:patch', context.nuiMessages[2].type)
  h.assertEqual('Visible', context.nuiMessages[2].patches[1].props.value)
end)

h.test('lui re-renders when tracked text values update', function()
  local lui, context = setupLui()
  local track = sure.getModule('track')
  local count, setCount = track.state('count', 1)

  lui.page('counter', function(ui)
    ui.text(count)
  end)

  setCount(2)

  h.assertEqual(2, #context.nuiMessages)
  h.assertEqual(1, context.nuiMessages[1].tree.children[1].props.value)
  h.assertEqual('lui:patch', context.nuiMessages[2].type)
  h.assertEqual('updateProps', context.nuiMessages[2].patches[1].op)
  h.assertEqual(2, context.nuiMessages[2].patches[1].props.value)
end)

h.test('lui maps tracked arrays and updates rendered children', function()
  local lui, context = setupLui()
  local track = sure.getModule('track')
  local items, setItems = track.state('items', { 'bread' })

  lui.page('inventory', function(ui)
    ui.foreach(items, function(item, index, itemUi)
      itemUi.text(index .. ':' .. item)
    end)
  end)

  setItems({ 'bread', 'water' })

  local firstList = context.nuiMessages[1].tree.children[1]
  local patch = context.nuiMessages[2].patches[1]
  local secondList = patch.node

  h.assertEqual('foreach', firstList.type)
  h.assertEqual('lui:patch', context.nuiMessages[2].type)
  h.assertEqual('replaceNode', patch.op)
  h.assertEqual(1, #firstList.children)
  h.assertEqual(2, #secondList.children)
  h.assertEqual('2:water', secondList.children[2].children[1].props.value)
end)

h.test('lui foreach derives stable item keys from table ids', function()
  local lui, context = setupLui()
  local track = sure.getModule('track')
  local items, setItems = track.state('keyedItems', {
    {
      id = 'first',
      label = 'First',
    },
  })

  lui.page('keyed-list', function(ui)
    ui.presence(function()
      ui.foreach(items, function(item, _, itemUi)
        itemUi.motionDiv({
          exit = {
            opacity = 0,
          },
        }, function()
          itemUi.text(item.label)
        end)
      end)
    end)
  end)

  setItems({
    {
      id = 'first',
      label = 'First',
    },
    {
      id = 'second',
      label = 'Second',
    },
  })

  local list = context.nuiMessages[1].tree.children[1].children[1]
  local patch = context.nuiMessages[2].patches[1]

  h.assertEqual('first', list.children[1].props.key)
  h.assertEqual('replaceNode', patch.op)
  h.assertEqual('second', patch.node.children[2].props.key)
end)

h.test('lui foreach supports explicit keyBy names for presence lists', function()
  local lui, context = setupLui()
  local items = {
    {
      noticeId = 'n-1',
      message = 'Hello',
    },
  }

  lui.page('notifications', function(ui)
    ui.motionStack({
      className = 'fixed right-6 top-6 w-80',
    }, function()
      ui.presence({
        mode = 'popLayout',
      }, function()
        ui.foreach(items, function(item, _, itemUi)
          itemUi.motionDiv({
            layout = true,
          }, function()
            itemUi.text(item.message)
          end)
        end, {
          keyBy = 'noticeId',
        })
      end)
    end)
  end)

  local foreach = context.nuiMessages[1].tree.children[1].children[1].children[1]

  h.assertEqual('foreach', foreach.type)
  h.assertEqual('n-1', foreach.children[1].props.key)
end)

h.test('lui manages NUI focus and close messages', function()
  local lui, context = setupLui()

  lui.page('panel', function(ui)
    ui.text('Panel')
  end)

  lui.open('panel')
  lui.close('panel')

  h.assertTrue(context.nuiFocus[1].hasFocus)
  h.assertTrue(context.nuiFocus[1].hasCursor)
  h.assertFalse(context.nuiFocus[2].hasFocus)
  h.assertEqual('lui:visibility', context.nuiMessages[2].type)
  h.assertEqual(true, context.nuiMessages[2].visible)
  h.assertEqual(false, context.nuiMessages[3].visible)
end)

h.test('lui replays visible pages when NUI reports ready', function()
  local lui, context = setupLui()

  lui.page('panel', function(ui)
    ui.text('Panel')
  end)

  lui.open('panel')
  context.nuiCallbacks['lui:ready']({}, function() end)

  h.assertEqual('lui:render', context.nuiMessages[3].type)
  h.assertEqual('panel', context.nuiMessages[3].page)
  h.assertEqual('lui:visibility', context.nuiMessages[4].type)
  h.assertTrue(context.nuiMessages[4].visible)
end)

h.test('lui event handlers compose tracked functional updates with timer updates', function()
  local lui, context = setupLui()
  local track = sure.getModule('track')
  local count, setCount = track.state('raceCount', 0)

  local increment = function(value)
    return value + 1
  end

  lui.page('counter', function(ui)
    ui.button('Increment', function()
      setCount(increment)
    end)
    ui.text(count)
  end)

  lui.open('counter')

  local actionId = context.nuiMessages[1].tree.children[1].props.actionId
  context.nuiCallbacks['lui:event']({
    actionId = actionId,
  }, function() end)
  context.nuiCallbacks['lui:event']({
    actionId = actionId,
  }, function() end)
  setCount(increment)

  h.assertEqual(3, count())
end)
