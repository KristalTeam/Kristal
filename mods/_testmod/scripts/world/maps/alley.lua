return {
  version = "1.10",
  luaversion = "5.1",
  tiledversion = "1.10.2",
  class = "",
  orientation = "orthogonal",
  renderorder = "right-down",
  width = 21,
  height = 12,
  tilewidth = 40,
  tileheight = 40,
  nextlayerid = 16,
  nextobjectid = 96,
  properties = {
    ["border"] = "castle",
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
      firstgid = 426,
      filename = "../tilesets/street_edges.tsx"
    },
    {
      name = "test_battleborder",
      firstgid = 634,
      filename = "../tilesets/test_battleborder.tsx"
    },
    {
      name = "alley_animated",
      firstgid = 649,
      filename = "../tilesets/alley_animated.tsx",
      exportfilename = "../tilesets/alley_animated.lua"
    },
    {
      name = "alley_buildings_glitch",
      firstgid = 682,
      filename = "../tilesets/alley_buildings_glitch.tsx",
      exportfilename = "../tilesets/alley_buildings_glitch.lua"
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
        466, 461, 473, 473, 475, 476, 477, 473, 473, 473, 553, 554, 555, 473, 473, 473, 473, 543, 544, 544, 544,
        355, 355, 355, 355, 355, 355, 355, 356, 354, 355, 356, 354, 355, 355, 355, 355, 355, 356, 354, 355, 355,
        370, 706, 370, 370, 370, 370, 370, 371, 399, 734, 401, 369, 370, 738, 370, 370, 370, 371, 369, 370, 370,
        400, 400, 400, 400, 400, 400, 400, 401, 399, 718, 401, 399, 400, 400, 400, 400, 750, 401, 369, 706, 370,
        742, 400, 400, 400, 400, 734, 400, 401, 417, 415, 416, 399, 400, 726, 400, 400, 400, 401, 369, 370, 370,
        415, 415, 415, 415, 415, 415, 415, 416, 196, 196, 196, 417, 415, 415, 415, 415, 415, 416, 369, 370, 370,
        49, 46, 655, 46, 49, 46, 49, 46, 49, 49, 49, 46, 49, 46, 49, 46, 655, 46, 369, 746, 370,
        63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 369, 370, 370,
        73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 369, 714, 370,
        355, 355, 355, 355, 355, 355, 356, 354, 355, 355, 355, 355, 355, 355, 355, 356, 73, 73, 369, 370, 370,
        730, 370, 370, 370, 370, 738, 371, 369, 370, 370, 370, 370, 370, 698, 370, 371, 73, 73, 369, 370, 370,
        370, 370, 370, 370, 370, 370, 371, 369, 370, 738, 370, 370, 370, 370, 370, 371, 73, 73, 369, 738, 370
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
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 637, 645, 645, 645, 638, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        645, 645, 645, 645, 645, 645, 645, 646, 0, 0, 0, 644, 645, 645, 645, 645, 645, 645, 638, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 639, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 639, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 639, 0, 0,
        635, 635, 635, 635, 635, 635, 635, 635, 635, 635, 635, 635, 635, 635, 635, 636, 0, 0, 639, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 641, 0, 0, 639, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 641, 0, 0, 639, 0, 0
      }
    },
    {
      type = "objectgroup",
      draworder = "topdown",
      id = 4,
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
            ["exit_delay"] = 1,
            ["exit_sound"] = "doorclose",
            ["facing"] = "down",
            ["map"] = "alley2",
            ["marker"] = "entry",
            ["sound"] = "dooropen"
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
