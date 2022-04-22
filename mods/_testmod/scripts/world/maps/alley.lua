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
  nextobjectid = 93,
  properties = {
    ["light"] = false,
    ["music"] = "cybercity",
    ["name"] = "Test City - Sugarplum Alley"
  },
  tilesets = {
    {
      name = "city_alley",
      firstgid = 1,
      tilewidth = 40,
      tileheight = 40,
      spacing = 4,
      margin = 2,
      columns = 10,
      image = "../../../assets/sprites/tilesets/city_alley.png",
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
      image = "../../../assets/sprites/tilesets/alley.png",
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
      image = "../../../assets/sprites/tilesets/street_edges.png",
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
      image = "../../../assets/sprites/tilesets/test_battleborder.png",
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
    },
    {
      name = "alley_animated",
      firstgid = 697,
      tilewidth = 40,
      tileheight = 40,
      spacing = 4,
      margin = 2,
      columns = 6,
      image = "../../../assets/sprites/tilesets/alley_animated.png",
      imagewidth = 264,
      imageheight = 264,
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
      tilecount = 36,
      tiles = {
        {
          id = 3,
          animation = {
            {
              tileid = 3,
              duration = 1000
            },
            {
              tileid = 4,
              duration = 1000
            },
            {
              tileid = 5,
              duration = 1000
            },
            {
              tileid = 3,
              duration = 1000
            }
          }
        },
        {
          id = 6,
          animation = {
            {
              tileid = 6,
              duration = 1000
            },
            {
              tileid = 7,
              duration = 1000
            },
            {
              tileid = 8,
              duration = 1000
            },
            {
              tileid = 6,
              duration = 1000
            }
          }
        },
        {
          id = 9,
          animation = {
            {
              tileid = 9,
              duration = 1000
            },
            {
              tileid = 10,
              duration = 1000
            },
            {
              tileid = 11,
              duration = 1000
            },
            {
              tileid = 9,
              duration = 1000
            }
          }
        },
        {
          id = 12,
          animation = {
            {
              tileid = 12,
              duration = 1000
            },
            {
              tileid = 13,
              duration = 1000
            },
            {
              tileid = 14,
              duration = 1000
            },
            {
              tileid = 12,
              duration = 1000
            }
          }
        },
        {
          id = 15,
          animation = {
            {
              tileid = 15,
              duration = 1000
            },
            {
              tileid = 16,
              duration = 1000
            },
            {
              tileid = 17,
              duration = 1000
            },
            {
              tileid = 15,
              duration = 1000
            }
          }
        },
        {
          id = 18,
          animation = {
            {
              tileid = 18,
              duration = 1000
            },
            {
              tileid = 19,
              duration = 1000
            },
            {
              tileid = 20,
              duration = 1000
            },
            {
              tileid = 18,
              duration = 1000
            }
          }
        },
        {
          id = 21,
          animation = {
            {
              tileid = 21,
              duration = 1000
            },
            {
              tileid = 22,
              duration = 1000
            },
            {
              tileid = 23,
              duration = 1000
            },
            {
              tileid = 21,
              duration = 1000
            }
          }
        },
        {
          id = 24,
          animation = {
            {
              tileid = 24,
              duration = 1000
            },
            {
              tileid = 25,
              duration = 1000
            },
            {
              tileid = 26,
              duration = 1000
            },
            {
              tileid = 24,
              duration = 1000
            }
          }
        },
        {
          id = 27,
          animation = {
            {
              tileid = 27,
              duration = 1000
            },
            {
              tileid = 28,
              duration = 1000
            },
            {
              tileid = 29,
              duration = 1000
            },
            {
              tileid = 27,
              duration = 1000
            }
          }
        },
        {
          id = 30,
          animation = {
            {
              tileid = 30,
              duration = 1000
            },
            {
              tileid = 31,
              duration = 1000
            },
            {
              tileid = 32,
              duration = 1000
            },
            {
              tileid = 30,
              duration = 1000
            }
          }
        }
      }
    },
    {
      name = "alley_buildings_glitch",
      firstgid = 733,
      tilewidth = 40,
      tileheight = 40,
      spacing = 4,
      margin = 2,
      columns = 8,
      image = "../../../assets/sprites/tilesets/alley_buildings_glitch.png",
      imagewidth = 352,
      imageheight = 396,
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
      tilecount = 72,
      tiles = {
        {
          id = 8,
          animation = {
            {
              tileid = 8,
              duration = 1000
            },
            {
              tileid = 9,
              duration = 1000
            },
            {
              tileid = 10,
              duration = 1000
            },
            {
              tileid = 11,
              duration = 1000
            }
          }
        },
        {
          id = 12,
          animation = {
            {
              tileid = 12,
              duration = 1000
            },
            {
              tileid = 13,
              duration = 1000
            },
            {
              tileid = 14,
              duration = 1000
            },
            {
              tileid = 15,
              duration = 1000
            }
          }
        },
        {
          id = 16,
          animation = {
            {
              tileid = 16,
              duration = 1000
            },
            {
              tileid = 17,
              duration = 1000
            },
            {
              tileid = 18,
              duration = 1000
            },
            {
              tileid = 19,
              duration = 1000
            }
          }
        },
        {
          id = 20,
          animation = {
            {
              tileid = 20,
              duration = 1000
            },
            {
              tileid = 21,
              duration = 1000
            },
            {
              tileid = 22,
              duration = 1000
            },
            {
              tileid = 23,
              duration = 1000
            }
          }
        },
        {
          id = 24,
          animation = {
            {
              tileid = 24,
              duration = 1000
            },
            {
              tileid = 25,
              duration = 1000
            },
            {
              tileid = 26,
              duration = 1000
            },
            {
              tileid = 27,
              duration = 1000
            }
          }
        },
        {
          id = 28,
          animation = {
            {
              tileid = 28,
              duration = 1000
            },
            {
              tileid = 29,
              duration = 1000
            },
            {
              tileid = 30,
              duration = 1000
            },
            {
              tileid = 31,
              duration = 1000
            }
          }
        },
        {
          id = 32,
          animation = {
            {
              tileid = 32,
              duration = 1000
            },
            {
              tileid = 33,
              duration = 1000
            },
            {
              tileid = 34,
              duration = 1000
            },
            {
              tileid = 35,
              duration = 1000
            }
          }
        },
        {
          id = 36,
          animation = {
            {
              tileid = 36,
              duration = 1000
            },
            {
              tileid = 37,
              duration = 1000
            },
            {
              tileid = 38,
              duration = 1000
            },
            {
              tileid = 39,
              duration = 1000
            }
          }
        },
        {
          id = 40,
          animation = {
            {
              tileid = 40,
              duration = 1000
            },
            {
              tileid = 41,
              duration = 1000
            },
            {
              tileid = 42,
              duration = 1000
            },
            {
              tileid = 43,
              duration = 1000
            }
          }
        },
        {
          id = 44,
          animation = {
            {
              tileid = 44,
              duration = 1000
            },
            {
              tileid = 45,
              duration = 1000
            },
            {
              tileid = 46,
              duration = 1000
            },
            {
              tileid = 47,
              duration = 1000
            }
          }
        },
        {
          id = 48,
          animation = {
            {
              tileid = 48,
              duration = 1000
            },
            {
              tileid = 49,
              duration = 1000
            },
            {
              tileid = 50,
              duration = 1000
            },
            {
              tileid = 51,
              duration = 1000
            }
          }
        },
        {
          id = 52,
          animation = {
            {
              tileid = 52,
              duration = 1000
            },
            {
              tileid = 53,
              duration = 1000
            },
            {
              tileid = 54,
              duration = 1000
            },
            {
              tileid = 55,
              duration = 1000
            }
          }
        },
        {
          id = 56,
          animation = {
            {
              tileid = 56,
              duration = 1000
            },
            {
              tileid = 57,
              duration = 1000
            },
            {
              tileid = 58,
              duration = 1000
            },
            {
              tileid = 59,
              duration = 1000
            }
          }
        },
        {
          id = 60,
          animation = {
            {
              tileid = 60,
              duration = 1000
            },
            {
              tileid = 61,
              duration = 1000
            },
            {
              tileid = 62,
              duration = 1000
            },
            {
              tileid = 63,
              duration = 1000
            }
          }
        },
        {
          id = 64,
          animation = {
            {
              tileid = 64,
              duration = 1000
            },
            {
              tileid = 65,
              duration = 1000
            },
            {
              tileid = 66,
              duration = 1000
            },
            {
              tileid = 67,
              duration = 1000
            }
          }
        },
        {
          id = 68,
          animation = {
            {
              tileid = 68,
              duration = 1000
            },
            {
              tileid = 69,
              duration = 1000
            },
            {
              tileid = 70,
              duration = 1000
            },
            {
              tileid = 71,
              duration = 1000
            }
          }
        }
      }
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
          name = "chest",
          type = "",
          shape = "rectangle",
          x = 640,
          y = 240,
          width = 40,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {
            ["item"] = "tensionbit"
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
