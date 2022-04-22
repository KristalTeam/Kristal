return {
  version = "1.5",
  luaversion = "5.1",
  tiledversion = "1.8.2",
  orientation = "orthogonal",
  renderorder = "right-down",
  width = 31,
  height = 12,
  tilewidth = 40,
  tileheight = 40,
  nextlayerid = 19,
  nextobjectid = 103,
  backgroundcolor = { 0, 0, 0 },
  properties = {
    ["light"] = true,
    ["music"] = "mus_school",
    ["name"] = "School"
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
    },
    {
      name = "schooltiles",
      firstgid = 805,
      tilewidth = 40,
      tileheight = 40,
      spacing = 0,
      margin = 0,
      columns = 9,
      image = "../../../assets/sprites/tilesets/bg_schooltiles_0.png",
      imagewidth = 360,
      imageheight = 480,
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
      tilecount = 108,
      tiles = {}
    }
  },
  layers = {
    {
      type = "tilelayer",
      x = 0,
      y = 0,
      width = 31,
      height = 12,
      id = 17,
      name = "Tile Layer 1",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      encoding = "lua",
      data = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 832, 806, 806, 806, 806, 806, 806, 806, 806, 806, 834, 0, 0, 0, 832, 806, 806, 806, 806, 806, 806, 806, 806, 806, 834, 0, 0, 0,
        0, 0, 0, 832, 806, 806, 806, 806, 806, 806, 806, 806, 806, 834, 0, 0, 0, 832, 806, 806, 806, 806, 806, 806, 806, 806, 806, 834, 0, 0, 0,
        0, 0, 0, 814, 815, 815, 815, 815, 815, 815, 815, 815, 815, 816, 0, 0, 0, 814, 815, 815, 815, 815, 815, 815, 815, 815, 815, 816, 0, 0, 0,
        0, 0, 0, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 0, 0, 0,
        0, 0, 0, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 805, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 805, 805, 805, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 805, 805, 805, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 805, 805, 805, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 805, 805, 805, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
      }
    },
    {
      type = "tilelayer",
      x = 0,
      y = 0,
      width = 31,
      height = 12,
      id = 18,
      name = "Tile Layer 2",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      encoding = "lua",
      data = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 808, 809, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 808, 809, 0, 0, 0, 0,
        0, 0, 0, 0, 817, 818, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 817, 818, 0, 0, 0, 0,
        0, 0, 0, 0, 826, 827, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 826, 827, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
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
          id = 89,
          name = "",
          type = "",
          shape = "rectangle",
          x = 120,
          y = 320,
          width = 440,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 90,
          name = "",
          type = "",
          shape = "rectangle",
          x = 80,
          y = 240,
          width = 40,
          height = 80,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 91,
          name = "",
          type = "",
          shape = "rectangle",
          x = 120,
          y = 200,
          width = 880,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 94,
          name = "",
          type = "",
          shape = "rectangle",
          x = 1080,
          y = 200,
          width = 40,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 95,
          name = "",
          type = "",
          shape = "rectangle",
          x = 1120,
          y = 240,
          width = 40,
          height = 80,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 96,
          name = "",
          type = "",
          shape = "rectangle",
          x = 680,
          y = 320,
          width = 440,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 97,
          name = "",
          type = "",
          shape = "rectangle",
          x = 680,
          y = 360,
          width = 40,
          height = 120,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 98,
          name = "",
          type = "",
          shape = "rectangle",
          x = 520,
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
          x = 600,
          y = 320,
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
          x = 620,
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
          id = 54,
          name = "transition",
          type = "",
          shape = "rectangle",
          x = 560,
          y = 460,
          width = 120,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {
            ["map"] = "alley2",
            ["marker"] = "entry"
          }
        },
        {
          id = 84,
          name = "interactscript",
          type = "",
          shape = "rectangle",
          x = 160,
          y = 200,
          width = 81,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {
            ["scene"] = "test"
          }
        },
        {
          id = 100,
          name = "interactscript",
          type = "",
          shape = "rectangle",
          x = 560,
          y = 200,
          width = 120,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {
            ["scene"] = "enterdark"
          }
        },
        {
          id = 101,
          name = "darkdoor",
          type = "",
          shape = "rectangle",
          x = 576,
          y = 124,
          width = 88,
          height = 112,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 102,
          name = "transition",
          type = "",
          shape = "rectangle",
          x = 1000,
          y = 200,
          width = 80,
          height = 40,
          rotation = 0,
          visible = true,
          properties = {
            ["map"] = "alley2",
            ["marker"] = "entry"
          }
        }
      }
    }
  }
}
