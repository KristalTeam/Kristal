return {
  version = "1.5",
  luaversion = "5.1",
  tiledversion = "1.8.4",
  orientation = "orthogonal",
  renderorder = "right-down",
  width = 21,
  height = 12,
  tilewidth = 40,
  tileheight = 40,
  nextlayerid = 16,
  nextobjectid = 99,
  properties = {
    ["light"] = false,
    ["music"] = "cybercity",
    ["name"] = "Test City - Sugarplum Alley"
  },
  tilesets = {
    {
      name = "city_alley",
      firstgid = 1,
      filename = "../tilesets/city_alley.tsx"
    },
    {
      name = "alley",
      firstgid = 111,
      filename = "../tilesets/alley.tsx"
    },
    {
      name = "street_edges",
      firstgid = 472,
      filename = "../tilesets/street_edges.tsx"
    },
    {
      name = "test_battleborder",
      firstgid = 682,
      filename = "../tilesets/test_battleborder.tsx"
    },
    {
      name = "alley_animated",
      firstgid = 697,
      filename = "../tilesets/alley_animated.tsx"
    },
    {
      name = "alley_buildings_glitch",
      firstgid = 733,
      filename = "../tilesets/alley_buildings_glitch.tsx"
    }
  },
  layers = {
    {
      type = "tilelayer",
      x = 0,
      y = 0,
      width = 21,
      height = 12,
      id = 1,
      name = "tiles",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      encoding = "lua",
      data = {
        512, 507, 519, 519, 521, 522, 523, 519, 519, 519, 599, 600, 601, 519, 519, 519, 519, 589, 590, 590, 590,
        355, 355, 355, 355, 355, 355, 355, 356, 354, 355, 356, 354, 355, 355, 355, 355, 355, 356, 354, 355, 355,
        370, 757, 370, 370, 370, 370, 370, 371, 399, 785, 401, 369, 370, 789, 370, 370, 370, 371, 369, 370, 370,
        400, 400, 400, 400, 400, 400, 400, 401, 399, 769, 401, 399, 400, 400, 400, 400, 801, 401, 369, 757, 370,
        793, 400, 400, 400, 400, 785, 400, 401, 417, 415, 416, 399, 400, 777, 400, 400, 400, 401, 369, 370, 370,
        415, 415, 415, 415, 415, 415, 415, 416, 196, 196, 196, 417, 415, 415, 415, 415, 415, 416, 369, 370, 370,
        49, 46, 703, 46, 49, 46, 49, 46, 49, 49, 49, 46, 49, 46, 49, 46, 703, 46, 369, 797, 370,
        63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 369, 370, 370,
        73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 369, 765, 370,
        355, 355, 355, 355, 355, 355, 356, 354, 355, 355, 355, 355, 355, 355, 355, 356, 73, 73, 369, 370, 370,
        781, 370, 370, 370, 370, 789, 371, 369, 370, 370, 370, 370, 370, 749, 370, 371, 73, 73, 369, 370, 370,
        370, 370, 370, 370, 370, 370, 371, 369, 370, 789, 370, 370, 370, 370, 370, 371, 73, 73, 369, 789, 370
      }
    },
    {
      type = "tilelayer",
      x = 0,
      y = 0,
      width = 21,
      height = 12,
      id = 5,
      name = "battleborder",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      encoding = "lua",
      data = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 685, 693, 693, 693, 686, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        693, 693, 693, 693, 693, 693, 693, 694, 0, 0, 0, 692, 693, 693, 693, 693, 693, 693, 686, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 687, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 687, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 687, 0, 0,
        683, 683, 683, 683, 683, 683, 683, 683, 683, 683, 683, 683, 683, 683, 683, 684, 0, 0, 687, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 689, 0, 0, 687, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 689, 0, 0, 687, 0, 0
      }
    },
    {
      type = "objectgroup",
      draworder = "topdown",
      id = 4,
      name = "collision",
      visible = true,
      opacity = 0.5,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      objects = {
        {
          id = 23,
          name = "",
          type = "",
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
          id = 24,
          name = "",
          type = "",
          shape = "rectangle",
          x = 320,
          y = 160,
          width = 120,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 25,
          name = "",
          type = "",
          shape = "rectangle",
          x = 440,
          y = 200,
          width = 280,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 26,
          name = "",
          type = "",
          shape = "rectangle",
          x = 720,
          y = 240,
          width = 40,
          height = 240,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 28,
          name = "",
          type = "",
          shape = "rectangle",
          x = 600,
          y = 360,
          width = 40,
          height = 120,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 29,
          name = "",
          type = "",
          shape = "rectangle",
          x = 0,
          y = 360,
          width = 600,
          height = 40,
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
      name = "paths",
      visible = true,
      opacity = 0.5,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      objects = {
        {
          id = 78,
          name = "virovirokun",
          type = "",
          shape = "ellipse",
          x = 168.033,
          y = 93.8198,
          width = 425.574,
          height = 378.984,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 93,
          name = "outta_here",
          type = "",
          shape = "polyline",
          x = 380,
          y = 300,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          polyline = {
            { x = 0, y = 0 },
            { x = 300, y = 0 },
            { x = 300, y = 200 }
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
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      objects = {
        {
          id = 16,
          name = "spawn",
          type = "",
          shape = "rectangle",
          x = 360,
          y = 280,
          width = 40,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 55,
          name = "shop_exit",
          type = "",
          shape = "point",
          x = 40,
          y = 320,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 90,
          name = "entry_down",
          type = "",
          shape = "point",
          x = 683,
          y = 425,
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
          name = "savepoint",
          type = "",
          shape = "rectangle",
          x = 360,
          y = 185,
          width = 40,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 54,
          name = "transition",
          type = "",
          shape = "rectangle",
          x = 640,
          y = 480,
          width = 80,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {
            ["map"] = "alley2",
            ["marker"] = "entry"
          }
        },
        {
          id = 74,
          name = "enemy",
          type = "",
          shape = "rectangle",
          x = 520,
          y = 320,
          width = 40,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {
            ["actor"] = "virovirokun",
            ["chase"] = false,
            ["encounter"] = "virovirokun",
            ["path"] = "virovirokun",
            ["progress"] = "-0.1"
          }
        },
        {
          id = 84,
          name = "interactable",
          type = "",
          shape = "rectangle",
          x = 80,
          y = 200,
          width = 81,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {
            ["cutscene"] = "test"
          }
        },
        {
          id = 86,
          name = "cybertrash",
          type = "",
          shape = "rectangle",
          x = 640,
          y = 240,
          width = 40,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {
            ["item"] = "cd_bagel"
          }
        },
        {
          id = 89,
          name = "transition",
          type = "",
          shape = "rectangle",
          x = -40,
          y = 240,
          width = 40,
          height = 120,
          rotation = 0,
          visible = true,
          properties = {
            ["marker"] = "shop_exit",
            ["shop"] = "test"
          }
        }
      }
    }
  }
}
