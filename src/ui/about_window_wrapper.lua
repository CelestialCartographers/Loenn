-- Used to keep menubar reasonable
-- aboutWindow is updated by the about window, allows hotswaping

local aboutWindow = {}

aboutWindow.aboutWindow = nil

function aboutWindow.showAboutWindow(element)
    if aboutWindow.aboutWindow then
        aboutWindow.aboutWindow.showAboutWindow()
    end
end

return aboutWindow