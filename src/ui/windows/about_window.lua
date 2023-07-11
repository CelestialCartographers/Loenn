local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local languageRegistry = require("language_registry")
local utils = require("utils")
local widgetUtils = require("ui.widgets.utils")
local form = require("ui.forms.form")
local github = require("utils.github")
local configs = require("configs")
local meta = require("meta")

local aboutWindowWrapper = require("ui.about_window_wrapper")

local windowPersister = require("ui.window_position_persister")
local windowPersisterName = "about_window"

local aboutWindow = {}

local aboutWindowGroup = uiElements.group({})

local function openReadmeUrl()
    local author = configs.updater.githubAuthor
    local repository = configs.updater.githubRepository
    local url = github.getRepositoryReadmeUrl(author, repository)

    love.system.openURL(url)
end

local noPaddingSpacing = {
    style = {
        spacing = 8,
        padding = 8
    }
}

function aboutWindow.showAboutWindow()
    local language = languageRegistry.getLanguage()
    local windowTitle = tostring(language.ui.about_window.title)
    local readmeText = tostring(language.ui.about_window.readme_button)
    local description = tostring(language.ui.about_window.description)
    local credits = tostring(language.ui.about_window.credits)
    local versionText = string.format(tostring(language.ui.about_window.version), meta.version)

    local logoScaleX = 0.5
    local logoScaleY = 0.5
    local logoImage = love.graphics.newImage("assets/logo-256.png")
    local logoElement = uiElements.image(logoImage):with({
        scaleX = logoScaleX,
        scaleY = logoScaleY
    })
    local logoWidth = logoImage:getWidth() * logoScaleX
    local logoContainer = uiElements.group({logoElement})

    local readmeButton = uiElements.button(readmeText, openReadmeUrl)

    local windowContent = uiElements.column({
        logoContainer,
        uiElements.label(versionText),
        uiElements.label(description),
        uiElements.label(credits),
        readmeButton
    }):with({
        style = {
            spacing = 8,
            padding = 8
        }
    })

    local window = uiElements.window(windowTitle, windowContent)
    local windowCloseCallback = windowPersister.getWindowCloseCallback(windowPersisterName)

    windowContent:layout()

    local logoOffsetX = math.floor((windowContent.innerWidth - logoWidth) / 2)

    logoContainer:with(uiUtils.fillWidth(false))
    readmeButton:with(uiUtils.fillWidth(false))
    logoElement:with(uiUtils.at(logoOffsetX, 0), logoContainer.style.padding)

    windowPersister.trackWindow(windowPersisterName, window)
    aboutWindowGroup.parent:addChild(window)
    widgetUtils.addWindowCloseButton(window, windowCloseCallback)
    form.prepareScrollableWindow(window)

    return window
end

-- Group to get access to the main group and sanely inject windows in it
function aboutWindow.getWindow()
    aboutWindowWrapper.aboutWindow = aboutWindow

    return aboutWindowGroup
end

return aboutWindow