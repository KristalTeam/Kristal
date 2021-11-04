return {
  version = "1.5",
  luaversion = "5.1",
  tiledversion = "1.7.2",
  orientation = "orthogonal",
  renderorder = "right-down",
  width = 21,
  height = 12,
  tilewidth = 40,
  tileheight = 40,
  nextlayerid = 7,
  nextobjectid = 78,
  properties = {},
  tilesets = {
    {
      name = "city_alley",
      firstgid = 1,
      tilewidth = 40,
      tileheight = 40,
      spacing = 4,
      margin = 2,
      columns = 10,
      image = "../assets/sprites/tilesets/city_alley.png",
      imagewidth = 440,
      imageheight = 484,
      objectalignment = "unspecified",
      tileoffset = {
        x = 0,
        y = 0
      },
      grid = {
        orientation = "orthogonal",
        width = 40,
        height = 40
      },
      properties = {},
      wangsets = {},
      tilecount = 110,
      tiles = {}
    },
    {
      name = "alley",
      firstgid = 111,
      tilewidth = 40,
      tileheight = 40,
      spacing = 4,
      margin = 2,
      columns = 19,
      image = "../assets/sprites/tilesets/alley.png",
      imagewidth = 836,
      imageheight = 836,
      objectalignment = "unspecified",
      tileoffset = {
        x = 0,
        y = 0
      },
      grid = {
        orientation = "orthogonal",
        width = 40,
        height = 40
      },
      properties = {},
      wangsets = {},
      tilecount = 361,
      tiles = {}
    },
    {
      name = "street_edges",
      firstgid = 472,
      tilewidth = 40,
      tileheight = 40,
      spacing = 4,
      margin = 2,
      columns = 14,
      image = "../assets/sprites/tilesets/street_edges.png",
      imagewidth = 616,
      imageheight = 660,
      objectalignment = "unspecified",
      tileoffset = {
        x = 0,
        y = 0
      },
      grid = {
        orientation = "orthogonal",
        width = 40,
        height = 40
      },
      properties = {},
      wangsets = {},
      tilecount = 210,
      tiles = {}
    },
    {
      name = "test_battleborder",
      firstgid = 682,
      tilewidth = 40,
      tileheight = 40,
      spacing = 0,
      margin = 0,
      columns = 5,
      image = "../assets/sprites/tilesets/test_battleborder.png",
      imagewidth = 200,
      imageheight = 120,
      objectalignment = "unspecified",
      tileoffset = {
        x = 0,
        y = 0
      },
      grid = {
        orientation = "orthogonal",
        width = 40,
        height = 40
      },
      properties = {},
      wangsets = {},
      tilecount = 15,
      tiles = {}
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
        370, 370, 370, 370, 370, 370, 370, 371, 399, 400, 401, 369, 370, 370, 370, 370, 370, 371, 369, 370, 370,
        400, 400, 400, 400, 400, 400, 400, 401, 399, 400, 401, 399, 400, 400, 400, 400, 400, 401, 369, 370, 370,
        400, 400, 400, 400, 400, 400, 400, 401, 417, 415, 416, 399, 400, 400, 400, 400, 400, 401, 369, 370, 370,
        415, 415, 415, 415, 415, 415, 415, 416, 196, 196, 196, 417, 415, 415, 415, 415, 415, 416, 369, 370, 370,
        49, 46, 49, 46, 49, 46, 49, 46, 49, 49, 49, 46, 49, 46, 49, 46, 49, 46, 369, 370, 370,
        63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 369, 370, 370,
        73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 369, 370, 370,
        355, 355, 355, 355, 355, 355, 356, 354, 355, 355, 355, 355, 355, 355, 355, 356, 73, 73, 369, 370, 370,
        370, 370, 370, 370, 370, 370, 371, 369, 370, 370, 370, 370, 370, 370, 370, 371, 73, 73, 369, 370, 370,
        370, 370, 370, 370, 370, 370, 371, 369, 370, 370, 370, 370, 370, 370, 370, 371, 73, 73, 369, 370, 370
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
        },
        {
          id = 33,
          name = "",
          type = "",
          shape = "rectangle",
          x = -40,
          y = 240,
          width = 40,
          height = 120,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 42,
          name = "",
          type = "",
          shape = "polygon",
          x = 640,
          y = 240,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          polygon = {
            { x = 0, y = 0 },
            { x = 80, y = 80 },
            { x = 80, y = 0 }
          },
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
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      objects = {
        {
          id = 77,
          name = "virovirokun",
          type = "",
          shape = "polyline",
          x = 680,
          y = 440,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          polyline = {
            { x = 0, y = 0 },
            { x = 0, y = -120 },
            { x = -40, y = -160 },
            { x = -160, y = -160 },
            { x = -240, y = -200 },
            { x = -300, y = -280 },
            { x = -360, y = -200 },
            { x = -400, y = -160 },
            { x = -540, y = -160 }
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
          name = "entry_down",
          type = "",
          shape = "point",
          x = 680,
          y = 440,
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
          id = 52,
          name = "banana",
          type = "",
          shape = "rectangle",
          x = 120,
          y = 280,
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
            ["encounter"] = "virovirokun",
            ["path"] = "virovirokun"
          }
        }
      }
    }
  }
}
