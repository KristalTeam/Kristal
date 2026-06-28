return {
  version = "1.11",
  luaversion = "5.1",
  tiledversion = "1.12.1",
  class = "",
  orientation = "orthogonal",
  renderorder = "right-down",
  width = 20,
  height = 12,
  tilewidth = 40,
  tileheight = 40,
  nextlayerid = 9,
  nextobjectid = 102,
  properties = {
    ["name"] = "Test Map - Climbing"
  },
  tilesets = {
    {
      name = "castle",
      firstgid = 1,
      filename = "../tilesets/castle.tsx",
      exportfilename = "../tilesets/castle.lua"
    }
  },
  layers = {
    {
      type = "tilelayer",
      x = 0,
      y = 0,
      width = 20,
      height = 12,
      id = 1,
      name = "tiles",
      class = "",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      encoding = "lua",
      data = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 29, 34, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 29, 34, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 29, 34, 0, 0, 0, 0,
        12, 12, 12, 0, 12, 0, 0, 0, 0, 0, 0, 0, 0, 32, 29, 34, 0, 0, 0, 0,
        0, 0, 0, 0, 12, 0, 0, 0, 0, 0, 0, 0, 0, 32, 29, 34, 0, 0, 0, 0,
        0, 0, 0, 0, 18, 0, 0, 0, 0, 0, 0, 0, 0, 32, 29, 34, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 8, 9, 10, 0, 0, 32, 29, 34, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 14, 15, 16, 0, 0, 38, 35, 40, 0, 0, 0, 0,
        0, 0, 8, 9, 9, 9, 9, 9, 15, 15, 15, 9, 9, 9, 41, 9, 10, 0, 0, 0,
        0, 0, 20, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 22, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
      }
    },
    {
      type = "objectgroup",
      draworder = "topdown",
      id = 3,
      name = "collision",
      class = "",
      visible = true,
      opacity = 0.5,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      objects = {
        {
          id = 77,
          name = "",
          type = "",
          shape = "rectangle",
          x = 600,
          y = 280,
          width = 80,
          height = 40,
          rotation = 0,
          opacity = 1,
          visible = true,
          properties = {}
        },
        {
          id = 79,
          name = "",
          type = "",
          shape = "rectangle",
          x = 680,
          y = 320,
          width = 40,
          height = 80,
          rotation = 0,
          opacity = 1,
          visible = true,
          properties = {}
        },
        {
          id = 80,
          name = "",
          type = "",
          shape = "rectangle",
          x = 80,
          y = 400,
          width = 600,
          height = 40,
          rotation = 0,
          opacity = 1,
          visible = true,
          properties = {}
        },
        {
          id = 82,
          name = "",
          type = "",
          shape = "rectangle",
          x = 440,
          y = 240,
          width = 40,
          height = 80,
          rotation = 0,
          opacity = 1,
          visible = true,
          properties = {}
        },
        {
          id = 83,
          name = "",
          type = "",
          shape = "rectangle",
          x = 320,
          y = 200,
          width = 120,
          height = 40,
          rotation = 0,
          opacity = 1,
          visible = true,
          properties = {}
        },
        {
          id = 84,
          name = "",
          type = "",
          shape = "rectangle",
          x = 200,
          y = 280,
          width = 80,
          height = 40,
          rotation = 0,
          opacity = 1,
          visible = true,
          properties = {}
        },
        {
          id = 85,
          name = "",
          type = "",
          shape = "rectangle",
          x = 480,
          y = 280,
          width = 80,
          height = 40,
          rotation = 0,
          opacity = 1,
          visible = true,
          properties = {}
        },
        {
          id = 86,
          name = "",
          type = "",
          shape = "rectangle",
          x = 280,
          y = 240,
          width = 40,
          height = 80,
          rotation = 0,
          opacity = 1,
          visible = true,
          properties = {}
        },
        {
          id = 89,
          name = "",
          type = "",
          shape = "rectangle",
          x = 40,
          y = 320,
          width = 40,
          height = 80,
          rotation = 0,
          opacity = 1,
          visible = true,
          properties = {}
        },
        {
          id = 92,
          name = "",
          type = "",
          shape = "rectangle",
          x = 80,
          y = 280,
          width = 80,
          height = 40,
          rotation = 0,
          opacity = 1,
          visible = true,
          properties = {}
        }
      }
    },
    {
      type = "objectgroup",
      draworder = "topdown",
      id = 7,
      name = "climbing",
      class = "objects",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      objects = {
        {
          id = 97,
          name = "",
          type = "climbarea",
          shape = "rectangle",
          x = 160,
          y = 120,
          width = 40,
          height = 120,
          rotation = 0,
          opacity = 1,
          visible = true,
          properties = {}
        },
        {
          id = 98,
          name = "",
          type = "climbarea",
          shape = "rectangle",
          x = -80,
          y = 120,
          width = 200,
          height = 40,
          rotation = 0,
          opacity = 1,
          visible = true,
          properties = {}
        }
      }
    },
    {
      type = "objectgroup",
      draworder = "topdown",
      id = 4,
      name = "markers",
      class = "",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      objects = {
        {
          id = 73,
          name = "slide",
          type = "",
          shape = "point",
          x = 580,
          y = -50,
          width = 0,
          height = 0,
          rotation = 0,
          opacity = 1,
          visible = true,
          properties = {
            ["player_state"] = "SLIDE_LOCK"
          }
        },
        {
          id = 74,
          name = "spawn",
          type = "",
          shape = "point",
          x = 380,
          y = 380,
          width = 0,
          height = 0,
          rotation = 0,
          opacity = 1,
          visible = true,
          properties = {}
        },
        {
          id = 95,
          name = "",
          type = "",
          shape = "point",
          x = 180,
          y = 380,
          width = 0,
          height = 0,
          rotation = 0,
          opacity = 1,
          visible = true,
          properties = {}
        },
        {
          id = 101,
          name = "entry_left",
          type = "",
          shape = "point",
          x = 60,
          y = 140,
          width = 0,
          height = 0,
          rotation = 0,
          opacity = 1,
          visible = true,
          properties = {
            ["player_state"] = "CLIMB"
          }
        }
      }
    },
    {
      type = "objectgroup",
      draworder = "topdown",
      id = 5,
      name = "objects",
      class = "",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      objects = {
        {
          id = 72,
          name = "slidearea",
          type = "",
          shape = "rectangle",
          x = 560,
          y = -80,
          width = 40,
          height = 400,
          rotation = 0,
          opacity = 1,
          visible = true,
          properties = {
            ["lock"] = true
          }
        },
        {
          id = 90,
          name = "chest",
          type = "",
          shape = "rectangle",
          x = 360,
          y = 250,
          width = 40,
          height = 40,
          rotation = 0,
          opacity = 1,
          visible = true,
          properties = {
            ["item"] = "cheesekey"
          }
        },
        {
          id = 93,
          name = "climbentry",
          type = "",
          shape = "rectangle",
          x = 160,
          y = 280,
          width = 40,
          height = 40,
          rotation = 0,
          opacity = 1,
          visible = true,
          properties = {
            ["target"] = { id = 94 }
          }
        },
        {
          id = 94,
          name = "climbexit",
          type = "",
          shape = "rectangle",
          x = 160,
          y = 200,
          width = 40,
          height = 40,
          rotation = 0,
          opacity = 1,
          visible = true,
          properties = {
            ["target"] = { id = 95 }
          }
        },
        {
          id = 100,
          name = "transition",
          type = "",
          shape = "rectangle",
          x = 0,
          y = 120,
          width = 20,
          height = 40,
          rotation = 0,
          opacity = 1,
          visible = true,
          properties = {
            ["map"] = "voidclimb",
            ["marker"] = "entry_right"
          }
        }
      }
    }
  }
}
