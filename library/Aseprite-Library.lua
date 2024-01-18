---@meta

-- Globals namespaces
---@class (exact) app https://www.aseprite.org/api/app
---@field site Site
---@field range Range
---@field cel Cel
---@field frame Frame
---@field image Image
---@field layer Layer
---@field sprite Sprite
---@field tag Tag
---@field tool Tool
---@field brush Brush
---@field editor Editor
---@field window Window
---@field pixelColor pixelColor
---@field version Version
---@field apiVersion Version
---@field fgColor Color
---@field bgColor Color
---@field isUIAvailable boolean
---@field sprites Sprite[]
---@field params table
---@field alert fun(title: string | { title: string, text?: string | string[], buttons?: string | string[] }, text?: string | string[], buttons?: string | string[])
---@field open fun(filename: string): Sprite | nil
---@field exit function
---@field transaction fun(text?: string, function: function)
---@field command command
---@field preferences preferences
---@field fs fs
---@field theme theme
---@field uiScale number
---@field refresh function
---@field undo function
---@field useTool fun(tool: string | Tool, color: Color, bgColor: Color, brush: Brush, points: Point[], cel: Cel, layer: Layer, frame: Frame, ink: Ink, button: MouseButton.LEFT | MouseButton.RIGHT, opacity: integer, contiguous: boolean, tolerance: integer, freehandAlgorithm: 0 | 1, selection: SelectionMode.REPLACE | SelectionMode.ADD | SelectionMode.SUBTRACT | SelectionMode.INTERSECT, tilemapMode: TilemapMode.PIXELS | TilemapMode.TILES, tilesetMode: TilesetMode.MANUAL | TilesetMode.AUTO | TilesetMode.STACK)
---@field events Events
-- @deprecated
---@field activeSprite Sprite | nil
---@field activeLayer Layer
---@field activeFrame Frame
---@field activeCel Cel
---@field activeImage Image
---@field activeTag Tag
---@field activeTool Tool
---@field activeBrush Brush
app = {}

---@class (exact) pixelColor https://www.aseprite.org/api/pixelcolor
---@field rgba fun(red: number, green: number, blue: number, alpha?: number): Color
---@field rgbaR function
---@field rgbaG function
---@field rgbaB function
---@field rgbaA function
---@field graya function
---@field grayaV function
---@field grayaA function
pixelColor = {}

---@class (exact) command https://www.aseprite.org/api/app_command
-- TODO
command = {}

---@class (exact) preferences https://www.aseprite.org/api/app_preferences
---@field tool function
---@field document function
preferences = {}

---@class (exact) fs https://www.aseprite.org/api/app_fs
---@field pathSeparator string
---@field filePath function
---@field fileName function
---@field fileExtension function
---@field fileTitle function
---@field filePathAndTitle function
---@field normalizePath function
---@field joinPath function
---@field currentPath string
---@field appPath string
---@field tempPath string
---@field userDocsPath string
---@field userConfigPath string
---@field isFile function
---@field isDirectory function
---@field fileSize function
---@field listFiles function
---@field makeDirectory function
---@field makeAllDirectories function
---@field removeDirectory function
fs = {}

---@class (exact) theme https://www.aseprite.org/api/app_theme
---@field color Color
---@field dimension number
---@field styleMetrics function
theme = {}

---@class (exact) json https://www.aseprite.org/api/json
---@field decode function
---@field encode function
json = {}

-- Constants

---@enum (exact) Align https://www.aseprite.org/api/align
Align = {
    LEFT = 0,
    CENTER = 1,
    RIGHT = 2,
    TOP = 3,
    BOTTOM = 4,
}

---@enum (exact) AniDir https://www.aseprite.org/api/anidir
AniDir = {
    FORWARD = 0,
    REVERSE = 1,
    PING_PONG = 2,
    PING_PONG_REVERSE = 3,
}

---@enum (exact) BlendMode https://www.aseprite.org/api/blendmode
BlendMode = {
    NORMAL = 0,
    SRC = 1,
    MULTIPLY = 2,
    SCREEN = 3,
    OVERLAY = 4,
    DARKEN = 5,
    LIGHTEN = 6,
    COLOR_DODGE = 7,
    COLOR_BURN = 8,
    HARD_LIGHT = 9,
    SOFT_LIGHT = 10,
    DIFFERENCE = 11,
    EXCLUSION = 12,
    HSL_HUE = 13,
    HSL_SATURATION = 14,
    HSL_COLOR = 15,
    HSL_LUMINOSITY = 16,
    ADDITION = 17,
    SUBTRACT = 18,
    DIVIDE = 19,
}

---@enum (exact) BrushPattern https://www.aseprite.org/api/brishpattern
BrushPattern = {
    NONE = 0,
    ORIGIN = 1,
    TARGET = 2,
}

---@enum (exact) BrushType https://www.aseprite.org/api/brushtype
BrushType = {
    CIRCLE = 0,
    SQUARE = 1,
    LINE = 2,
    IMAGE = 3,
}

---@enum (exact) ColorMode https://www.aseprite.org/api/colormode
ColorMode = {
    RGB = 0,
    GRAY = 1,
    INDEXED = 2,
    TILEMAP = 3,
}

---@enum (exact) FilterChannels https://www.aseprite.org/api/filterchannels
FilterChannels = {
    RED = 0,
    GREEN = 1,
    BLUE = 2,
    ALPHA = 3,
    GRAY = 4,
    INDEX = 5,
    RGB = 6,
    RGBA = 7,
    GRAYA = 8,
}

---@enum (exact) Ink https://www.aseprite.org/api/ink
Ink = {
    SIMPLE = 0,
    ALPHA_COMPOSITING = 1,
    COPY_COLOR = 2,
    LOCK_ALPHA = 3,
    SHADING = 4,
}

---@enum (exact) MouseButton https://www.aseprite.org/api/mousebutton
MouseButton = {
    NONE = 0,
    LEFT = 1,
    RIGHT = 2,
    MIDDLE = 3,
    X1 = 4,
    X2 = 5,
}

---@enum (exact) MouseCursor https://www.aseprite.org/api/mousecursor
MouseCursor = {
    NONE = 0,
    ARROW = 1,
    CROSSHAIR = 2,
    POINTER = 3,
    NOT_ALLOWED = 4,
    GRAB = 5,
    GRABBING = 6,
    MOVE = 7,
    NS_RESIZE = 8,
    WE_RESIZE = 9,
    N_RESIZE = 10,
    NE_RESIZE = 11,
    E_RESIZE = 12,
    SE_RESIZE = 13,
    S_RESIZE = 14,
    SW_RESIZE = 15,
    W_RESIZE = 16,
    NW_RESIZE = 17,
}

---@enum (exact) RangeType https://www.aseprite.org/api/rangetype
RangeType = {
    EMPTY = 0,
    LAYERS = 1,
    FRAMES = 2,
    CELS = 3,
}

---@enum (exact) SelectionMode https://www.aseprite.org/api/selectionmode
SelectionMode = {
    REPLACE = 0,
    ADD = 1,
    SUBTRACT = 2,
    INTERSECT = 3,
}

---@enum (exact) SpriteSheetDataFormat https://www.aseprite.org/api/spritesheetdataformat
SpriteSheetDataFormat = {
    JSON_HASH = 0,
    JSON_ARRAY = 1,
}

---@enum (exact) SpriteSheetType https://www.aseprite.org/api/spritesheettype
SpriteSheetType = {
    HORIZONTAL = 0,
    VERTICAL = 1,
    ROWS = 2,
    COLUMNS = 3,
    PACKED = 4,
}

---@enum (exact) TilemapMode
TilemapMode = {
    PIXELS = 0,
    TILES = 1,
}

---@enum (exact) TilesetMode
TilesetMode = {
    MANUAL = 0,
    AUTO = 1,
    STACK = 2,
}

---@enum (exact) WebSocketMessageType https://www.aseprite.org/api/websocketmessagetype
WebSocketMessageType = {
    TEXT = 0,
    BINARY = 1,
    OPEN = 2,
    CLOSE = 3,
    PING = 4,
    PONG = 5,
    FRAGMENT = 6,
}

-- Classes/objects

---@class (exact) Brush https://www.aseprite.org/api/brush
---@field type BrushType
---@field size number 
---@field angle number
---@field image Image
---@field center Point
---@field pattern BrushPattern
---@field patternOrigin Point
Brush = {}

---@class (exact) Cel https://www.aseprite.org/api/cel
---@field sprite Sprite
---@field layer Layer
---@field frame Frame
---@field frameNumber number
---@field image Image
---@field bounds Rectangle
---@field position Point
---@field opacity number
---@field zIndex number
---@field color Color
---@field data string
---@field properties Properties
Cel = {}

---@class (exact) Color https://www.aseprite.org/api/color
---@field alpha number
---@field red number
---@field green number
---@field blue number
---@field hsvHue number
---@field hsvSaturation number
---@field hsvValue number
---@field hslHue number
---@field hslSaturation number
---@field hslLightness number
---@field hue number
---@field saturation number
---@field value number
---@field lightness number
---@field index number
---@field gray number
---@field rgbaPixel pixelColor
---@field grayPixel pixelColor
Color = {}

---@class (exact) ColorSpace https://www.aseprite.org/api/colorspace
---@field name string
ColorSpace = {}

---@class (exact) Dialog https://www.aseprite.org/api/dialog
-- TODO

---@class (exact) Editor https://www.aseprite.org/api/editor
---@field sprite Sprite
---@field spritePos Point
---@field mousePos Point
---@field askPoint function
---@field cancel function
Editor = {}

---@class (exact) Events https://www.aseprite.org/api/events
---@field on function
---@field off function
Events = {}

---@class (exact) Frame https://www.aseprite.org/api/frame
---@field sprite Sprite
---@field frameNumber number
---@field duration number
---@field previous Frame
---@field next Frame
Frame = {}

---@class (exact) GraphicsContext https://www.aseprite.org/api/graphicscontext
---@field width number
---@field height number
---@field antialias boolean
---@field color Color
---@field strokeWidth number
---@field blendMode BlendMode
---@field opacity number
---@field theme theme
---@field save function
---@field restore function
---@field clip function
---@field strokeRect function
---@field fillRect function
---@field fillText function
---@field measureText function
---@field drawImage function
---@field drawThemeImage function
---@field drawThemeRect function
---@field beginPath function
---@field closePath function
---@field moveTo function
---@field lineTo function
---@field cubicTo function
---@field oval function
---@field rect function
---@field roundedRect function
---@field stroke function
---@field fill function
GraphicsContext = {}

---@class (exact) Image https://www.aseprite.org/api/image
---@field clone function
---@field id number
---@field version number
---@field width number
---@field height number
---@field bounds Rectangle
---@field colorMode ColorMode
---@field spec ImageSpec
---@field cel Cel
---@field bytes string
---@field rowStride number
---@field bytesPerPixel number
---@field clear function
---@field drawPixel function
---@field getPixel function
---@field drawImage function
---@field drawSprite function
---@field isEqual function
---@field isEmpty function
---@field isPlain function
---@field pixels function
---@field putPixel function
---@field putImage function
---@field putSprite function
---@field saveAs function
---@field resize function
---@field shrinkBounds function
Image = {}

---@class (exact) ImageSpec https://www.aseprite.org/api/imagespec
---@field colorMode ColorMode
---@field width number
---@field height number
---@field colorSpace ColorSpace
---@field transparentColor number
ImageSpec = {}

---@class (exact) KeyEvent https://www.aseprite.org/api/keyevent
---@field repeatCount number
---@field key string
---@field code string
---@field altKey boolean
---@field metaKey boolean
---@field ctrlKey boolean
---@field shiftKey boolean
---@field spaceKey boolean
---@field stopPropagation function
KeyEvent = {}

---@class (exact) Layer https://www.aseprite.org/api/layer


---@class (exact) MouseEvent https://www.aseprite.org/api/mouseevent
---@class (exact) Palette https://www.aseprite.org/api/palette
---@class (exact) Plugin https://www.aseprite.org/api/plugin
---@class (exact) Point https://www.aseprite.org/api/point
---@class (exact) Properties https://www.aseprite.org/api/properties
---@class (exact) Range https://www.aseprite.org/api/range
---@class (exact) Rectangle https://www.aseprite.org/api/rectangle
---@class (exact) Selection https://www.aseprite.org/api/selection

---@class (exact) Site https://www.aseprite.org/api/site
---@field sprite Sprite
---@field layer Layer
---@field cel Cel
---@field frame Frame
---@field frameNumber number
---@field image Image
Site = nil

---@class (exact) Size https://www.aseprite.org/api/size
---@field width number
---@field height number
---@field w number
---@field h number
---@field union fun(otherSize: Size): Size
Size = {}

---@return Size
---@overload fun(otherSize: Size): Size
---@overload fun(width: number, height: number): Size
---@overload fun(table: { width: number, height: number }): Size
---@overload fun(table: { w: number, h: number }): Size
---@overload fun(table: number[]): Size
function Size() end

---@class (exact) Slice https://www.aseprite.org/api/slice
---@field bounds Rectangle
---@field center Rectangle
---@field color Color
---@field data string
---@field properties Properties
---@field name string
---@field pivot Point
---@field sprite Sprite
Slice = {}

---@class (exact) Sprite https://www.aseprite.org/api/sprite


---@class (exact) Tag https://www.aseprite.org/api/tag
---@field sprite Sprite
---@field fromFrame Frame
---@field toFrame Frame
---@field frames number
---@field name string
---@field aniDir AniDir
---@field color Color
---@field repeats number
---@field data string
---@field properties Properties
Tag = {}

---@class (exact) Tile https://www.aseprite.org/api/tile
---@field index number
---@field image Image
---@field color Color
---@field data string
---@field properties Properties
Tile = {}

---@class (exact) Tileset https://www.aseprite.org/api/tileset
---@field name string
---@field grid any
---@field baseIndex number
---@field color Color
---@field data string
---@field properties Properties
---@field tile fun(tileSet: Tileset, index: number): Tile
---@field getTile fun(tileSet: Tileset, index: number): Tile
Tileset = {}

---@class (exact) Timer https://www.aseprite.org/api/timer
---@class (exact) Tool https://www.aseprite.org/api/tool

---@class (exact) TouchEvent https://www.aseprite.org/api/touchevent
---@field x number
---@field y number
---@field magnification number
TouchEvent = {}

---@class (exact) Version https://www.aseprite.org/api/version
---@field major number
---@field minor number
---@field patch number
---@field prereleaseLabel string
---@field prereleaseNumber number
Version = {}

---@param version string
---@return Version 
function Version(version) end

---@class (exact) WebSocket https://www.aseprite.org/api/websocket

---@class (exact) Window https://www.aseprite.org/api/window
---@field width number Returns the width of the main window.
---@field height number Returns the height of the main window.
---@field events Events Returns the Events object to associate functions that can act like listeners of specific Window events.
Windows = nil

-- Scripting
---@class (exact) plugin https://github.com/aseprite/api/blob/main/api/plugin.md#plugin
---@field name string
---@field path string
---@field preferences table
---@field newCommand fun(plugin: plugin, args: newCommandTable)
---@field newMenuGroup fun(plugin: plugin, args: newMenuGroupTable)
---@field newMenuSeparator fun(plugin: plugin, args: newMenuSeparatorTable)
plugin = {}

---@class (exact) newCommandTable
---@field id string
---@field title string
---@field group string
---@field onclick function
---@field onenabled fun(): boolean
newCommandTable = {}

---@class (exact) newMenuGroupTable
---@field id string
---@field title string
---@field group string
newMenuGroupTable = {}

---@class (exact) newMenuSeparatorTable
---@field group string
newMenuSeparatorTable = {}

---@param plugin plugin
function init(plugin) end

---@param plugin plugin
function exit(plugin) end