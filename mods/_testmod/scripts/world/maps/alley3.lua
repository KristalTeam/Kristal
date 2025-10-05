return {
  version = "1.9",
  luaversion = "5.1",
  tiledversion = "1.9.0",
  class = "",
  orientation = "orthogonal",
  renderorder = "right-down",
  width = 27,
  height = 14,
  tilewidth = 40,
  tileheight = 40,
  nextlayerid = 13,
  nextobjectid = 101,
  properties = {},
  tilesets = {
    {
      name = "alley_animated",
      firstgid = 1,
      filename = "../tilesets/alley_animated.tsx",
      exportfilename = "../tilesets/alley_animated.lua"
    },
    {
      name = "alley",
      firstgid = 34,
      filename = "../tilesets/alley.tsx"
    },
    {
      name = "city_alley",
      firstgid = 349,
      filename = "../tilesets/city_alley.tsx"
    }
  },
  layers = {
    {
      type = "tilelayer",
      x = 0,
      y = 0,
      width = 27,
      height = 14,
      id = 1,
      name = "Tile Layer 1",
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
        293, 293, 293, 293, 293, 293, 293, 294, 293, 293, 293, 293, 293, 293, 293, 293, 293, 293, 293, 293, 293, 293, 293, 293, 293, 292, 293,
        293, 293, 293, 293, 293, 293, 293, 294, 323, 323, 323, 323, 323, 323, 323, 323, 323, 323, 323, 323, 323, 323, 323, 323, 323, 292, 293,
        293, 293, 293, 293, 293, 293, 293, 294, 323, 323, 323, 323, 323, 323, 323, 323, 323, 323, 323, 323, 323, 323, 323, 323, 323, 292, 293,
        323, 323, 323, 323, 323, 323, 323, 324, 338, 338, 338, 338, 338, 338, 338, 338, 338, 338, 338, 338, 338, 338, 338, 338, 338, 292, 293,
        323, 323, 323, 323, 323, 323, 323, 324, 397, 397, 397, 397, 397, 397, 397, 397, 397, 397, 397, 397, 397, 397, 397, 397, 398, 292, 293,
        338, 338, 338, 338, 338, 338, 338, 339, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 409, 292, 293,
        401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 409, 292, 293,
        401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 446, 419, 419, 444, 401, 401, 401, 401, 409, 292, 293,
        278, 278, 278, 278, 278, 278, 278, 279, 419, 432, 401, 401, 401, 401, 401, 401, 409, 119, 119, 407, 401, 401, 401, 401, 409, 292, 293,
        293, 293, 293, 293, 293, 293, 293, 294, 119, 407, 401, 401, 401, 401, 436, 419, 420, 119, 119, 407, 401, 401, 401, 401, 409, 292, 293,
        293, 293, 293, 293, 293, 293, 293, 294, 119, 407, 401, 401, 401, 401, 414, 397, 397, 397, 397, 400, 401, 401, 401, 401, 409, 292, 293,
        293, 293, 293, 293, 293, 293, 293, 294, 119, 407, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 409, 292, 293,
        293, 293, 293, 293, 293, 293, 293, 294, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 292, 293,
        293, 293, 293, 293, 293, 293, 293, 294, 293, 293, 293, 293, 293, 293, 293, 293, 293, 293, 293, 293, 293, 293, 293, 293, 293, 292, 293
      }
    },
    {
      type = "objectgroup",
      draworder = "topdown",
      id = 4,
      name = "collision",
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
          id = 6,
          name = "",
          class = "",
          shape = "rectangle",
          x = 0,
          y = 200,
          width = 320,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 7,
          name = "",
          class = "",
          shape = "rectangle",
          x = 280,
          y = 160,
          width = 40,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 9,
          name = "",
          class = "",
          shape = "rectangle",
          x = 320,
          y = 120,
          width = 680,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 10,
          name = "",
          class = "",
          shape = "rectangle",
          x = 1000,
          y = 160,
          width = 40,
          height = 320,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 11,
          name = "",
          class = "",
          shape = "rectangle",
          x = 320,
          y = 480,
          width = 680,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 12,
          name = "",
          class = "",
          shape = "rectangle",
          x = 0,
          y = 320,
          width = 320,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 13,
          name = "",
          class = "",
          shape = "rectangle",
          x = 280,
          y = 360,
          width = 40,
          height = 120,
          rotation = 0,
          visible = true,
          properties = {}
        }
      }
    },
    {
      type = "objectgroup",
      draworder = "topdown",
      id = 6,
      name = "blockcollision",
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
          id = 91,
          name = "",
          class = "",
          shape = "polyline",
          x = 640,
          y = 280,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          polyline = {
            { x = 0, y = 0 },
            { x = 0, y = 80 },
            { x = -80, y = 80 },
            { x = -80, y = 160 },
            { x = 160, y = 160 },
            { x = 160, y = 0 },
            { x = 0, y = 0 }
          },
          properties = {}
        }
      }
    },
    {
      type = "objectgroup",
      draworder = "topdown",
      id = 10,
      name = "objects_buttons",
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
          id = 95,
          name = "tilebutton",
          class = "",
          shape = "rectangle",
          x = 680,
          y = 280,
          width = 40,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {
            ["blocks"] = true,
            ["cutscene"] = "alley3.puzzle_fail",
            ["group"] = "buton",
            ["once"] = true
          }
        },
        {
          id = 96,
          name = "tilebutton",
          class = "",
          shape = "rectangle",
          x = 560,
          y = 400,
          width = 40,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {
            ["blocks"] = true,
            ["cutscene"] = "alley3.puzzle_fail",
            ["group"] = "buton",
            ["once"] = true
          }
        }
      }
    },
    {
      type = "objectgroup",
      draworder = "topdown",
      id = 12,
      name = "paths",
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
          id = 100,
          name = "star",
          class = "",
          shape = "polygon",
          x = 400,
          y = 240,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          polygon = {
            { x = 0, y = 0 },
            { x = 80, y = 80 },
            { x = 60, y = -40 },
            { x = 160, y = -80 },
            { x = 40, y = -130 },
            { x = 0, y = -230 },
            { x = -40, y = -130 },
            { x = -160, y = -80 },
            { x = -60, y = -40 },
            { x = -80, y = 80 }
          },
          properties = {}
        }
      }
    },
    {
      type = "objectgroup",
      draworder = "topdown",
      id = 3,
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
          id = 2,
          name = "entry_left",
          class = "",
          shape = "point",
          x = 40,
          y = 280,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 5,
          name = "spawn",
          class = "",
          shape = "point",
          x = 360,
          y = 280,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        }
      }
    },
    {
      type = "objectgroup",
      draworder = "topdown",
      id = 2,
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
          id = 1,
          name = "interactable",
          class = "",
          shape = "rectangle",
          x = 360,
          y = 120,
          width = 40,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {
            ["cutscene"] = "testing.image"
          }
        },
        {
          id = 4,
          name = "transition",
          class = "",
          shape = "polygon",
          x = -40,
          y = 240,
          width = 40,
          height = 80,
          rotation = 0,
          visible = true,
          polygon = {
            { x = -10, y = -40 },
            { x = 40, y = 0 },
            { x = 40, y = 80 },
            { x = -10, y = 40 }
          },
          properties = {
            ["map"] = "alley2",
            ["marker"] = "entry_right"
          }
        },
        {
          id = 14,
          name = "forcefield",
          class = "",
          shape = "rectangle",
          x = 200,
          y = 200,
          width = 40,
          height = 160,
          rotation = 0,
          visible = true,
          properties = {
            ["flag"] = "alley3_enable_forcefield"
          }
        },
        {
          id = 26,
          name = "setflag",
          class = "",
          shape = "rectangle",
          x = 360,
          y = 160,
          width = 40,
          height = 320,
          rotation = 0,
          visible = true,
          properties = {
            ["flag"] = "alley3_enable_forcefield",
            ["once"] = true
          }
        },
        {
          id = 27,
          name = "npc",
          class = "",
          shape = "point",
          x = 400,
          y = 240,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {
            ["actor"] = "starwalker",
            ["cutscene"] = "alley3.starwalker_disable",
            ["path"] = "star",
            ["speed"] = 20
          }
        },
        {
          id = 29,
          name = "setflag",
          class = "",
          shape = "rectangle",
          x = 240,
          y = 240,
          width = 40,
          height = 80,
          rotation = 0,
          visible = true,
          properties = {
            ["flag"] = "alley3_seen_forcefield",
            ["once"] = true
          }
        },
        {
          id = 30,
          name = "setflag",
          class = "",
          shape = "rectangle",
          x = 840,
          y = 160,
          width = 40,
          height = 320,
          rotation = 0,
          visible = true,
          properties = {
            ["flag"] = "alley3_enable_starwalker",
            ["once"] = true
          }
        },
        {
          id = 72,
          name = "pushblock",
          class = "",
          shape = "rectangle",
          x = 600,
          y = 360,
          width = 40,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 90,
          name = "pushblock",
          class = "",
          shape = "rectangle",
          x = 720,
          y = 320,
          width = 40,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 99,
          name = "interactable",
          class = "",
          shape = "rectangle",
          x = 360,
          y = 480,
          width = 40,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {
            ["setflag"] = "clippy"
          }
        }
      }
    },
    {
      type = "objectgroup",
      draworder = "topdown",
      id = 5,
      name = "controllers",
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
          id = 28,
          name = "toggle",
          class = "",
          shape = "point",
          x = 320,
          y = 240,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {
            ["flag"] = "alley3_enable_forcefield",
            ["target"] = { id = 29 }
          }
        },
        {
          id = 32,
          name = "toggle",
          class = "",
          shape = "point",
          x = 800,
          y = 240,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {
            ["flag"] = "alley3_seen_forcefield",
            ["target"] = { id = 30 }
          }
        },
        {
          id = 33,
          name = "toggle",
          class = "",
          shape = "point",
          x = 460,
          y = 180,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {
            ["flag"] = "alley3_enable_starwalker",
            ["target"] = { id = 27 }
          }
        },
        {
          id = 98,
          name = "toggle",
          class = "",
          shape = "point",
          x = 240,
          y = 400,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {
            ["flag"] = "!clippy",
            ["target"] = { id = 13 }
          }
        }
      }
    }
  }
}
