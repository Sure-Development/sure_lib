local nui = {}

function nui.register(renderer)
  RegisterNUICallback('lui:ready', function(data, cb)
    renderer.handleReady(data, cb)
  end)

  RegisterNUICallback('lui:event', function(data, cb)
    renderer.handleEvent(data, cb)
  end)
end

return nui
