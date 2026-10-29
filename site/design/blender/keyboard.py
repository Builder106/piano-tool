# Builds the 61-key keyboard (C2 to C7) used by the showcase site, then renders the
# rest frame, one pressed crop per stage-one key, and the key geometry the site's hit
# areas are positioned from. Run inside Blender: exec(open(<this file>).read()).
#
# Layout follows lib/ui/keyboard/keyboard_geometry.dart: 36 white keys, black keys
# 0.62 of a white key wide and 0.6 of its length, centred on the white-key boundary.
import json
import math
import os

import bmesh
import bpy
from bpy_extras.object_utils import world_to_camera_view

HERE = os.path.dirname(os.path.abspath(__file__)) if '__file__' in dir() else ''
LOWEST, HIGHEST = 36, 96
PITCH = 0.0235          # white key pitch, metres
WHITE_W = 0.0224
WHITE_L = 0.150
WHITE_T = 0.022
BLACK_W = PITCH * 0.62
BLACK_L = WHITE_L * 0.6
BLACK_H = 0.012
PIVOT_Y = 0.45          # keys pivot well behind the name board
DIP = 0.0105            # front of a pressed key drops about 10 mm
BOARD_TILT = 15         # degrees back; steep enough that the lacquer mirrors the room, not the keys
BLACK_OFFSETS = {1, 3, 6, 8, 10}
WHITE_ORDINAL = [0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6]
WHITE_COUNT = 36
SPAN = WHITE_COUNT * PITCH
STAGE = list(range(60, 73))  # C4 to C5, white and black


def is_black(m):
    return m % 12 in BLACK_OFFSETS


def white_index(m):
    s = m - LOWEST
    return (s // 12) * 7 + WHITE_ORDINAL[m % 12]


def material(name, color, rough, **extra):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    p = mat.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = (*color, 1)
    p.inputs['Roughness'].default_value = rough
    for k, v in extra.items():
        p.inputs[k].default_value = v
    return mat


def box(name, x0, x1, y0, y1, z0, z1, mat, bevel=0.0012, origin=None, taper_top=0.0, front_slope=0.0):
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    ox, oy, oz = origin if origin else ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
    for v in bm.verts:
        x = x0 if v.co.x < 0 else x1
        y = y0 if v.co.y < 0 else y1
        z = z0 if v.co.z < 0 else z1
        if v.co.z > 0 and taper_top:
            x += taper_top if v.co.x < 0 else -taper_top
        if v.co.z > 0 and v.co.y < 0 and front_slope:
            y += front_slope
        v.co = (x - ox, y - oy, z - oz)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    ob.location = (ox, oy, oz)
    ob.data.materials.append(mat)
    if bevel:
        mod = ob.modifiers.new('bevel', 'BEVEL')
        mod.width = bevel
        mod.segments = 3
        mod.limit_method = 'ANGLE'
    for poly in me.polygons:
        poly.use_smooth = True
    bpy.context.scene.collection.objects.link(ob)
    return ob


def mark_mesh(name, mat, height):
    """The brand mark as one flat mesh, built from brand/mark.py so the decal and the SVGs
    share their geometry. Faces in XY, centred on the origin, `height` metres tall."""
    import importlib.util
    import re
    spec = importlib.util.spec_from_file_location('mark', os.path.join(HERE, '..', '..', '..', 'brand', 'mark.py'))
    mk = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mk)

    outlines = []
    for d in mk.loop_paths():
        nums = [float(v) for v in re.findall(r'-?\d+\.?\d*', d)]
        outlines.append(list(zip(nums[0::2], nums[1::2])))
    cx, cy, rx, ry, tilt = mk.HEAD.values()
    a = math.radians(tilt)
    outlines.append([(cx + rx * math.cos(u) * math.cos(a) - ry * math.sin(u) * math.sin(a),
                      cy + rx * math.cos(u) * math.sin(a) + ry * math.sin(u) * math.cos(a))
                     for u in (2 * math.pi * i / 48 for i in range(48))])
    sx, sy, sw, sh = mk.STEM
    outlines.append([(sx, sy), (sx + sw, sy), (sx + sw, sy + sh), (sx, sy + sh)])
    x1, x2, ly, lw = mk.LEDGER
    h = lw / 2
    cap = [(x2 + h * math.cos(u), ly + h * math.sin(u)) for u in (math.pi * (i / 8 - 0.5) for i in range(9))]
    outlines.append(cap + [(x1 + h * math.cos(u), ly + h * math.sin(u)) for u in (math.pi * (i / 8 + 0.5) for i in range(9))])
    for x, y, r in mk.end_caps():
        outlines.append([(x + r * math.cos(u), y + r * math.sin(u)) for u in (2 * math.pi * i / 16 for i in range(16))])

    pts = [p for o in outlines for p in o]
    x0, x1b = min(p[0] for p in pts), max(p[0] for p in pts)
    y0, y1b = min(p[1] for p in pts), max(p[1] for p in pts)
    s = height / (y1b - y0)
    mx, my = (x0 + x1b) / 2, (y0 + y1b) / 2

    bm = bmesh.new()
    for o in outlines:
        verts = [bm.verts.new(((x - mx) * s, -(y - my) * s, 0.0)) for x, y in o]
        bm.faces.new(verts)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    me.materials.append(mat)
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    bpy.context.view_layer.update()
    return ob


def build():
    scene = bpy.context.scene
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)

    ivory = material('key_white', (0.70, 0.70, 0.69), 0.24, **{'Coat Weight': 0.4, 'Coat Roughness': 0.08, 'Subsurface Weight': 0.08})
    ebony = material('key_black', (0.006, 0.006, 0.007), 0.55, **{'Specular IOR Level': 0.12})
    lacquer = material('lacquer', (0.006, 0.006, 0.007), 0.06, **{'Coat Weight': 1.0, 'Coat Roughness': 0.02})
    felt = material('felt', (0.022, 0.0025, 0.0035), 1.0, **{'Sheen Weight': 0.3})
    # Nickel, not gold: the brand is ink, paper and one blue (brand/README.md).
    nickel = material('decal_nickel', (0.72, 0.74, 0.77), 0.3, **{'Metallic': 1.0})

    for m in range(LOWEST, HIGHEST + 1):
        if is_black(m):
            b = (white_index(m) + 1) * PITCH
            ob = box(f'key_{m}', b - BLACK_W / 2, b + BLACK_W / 2, WHITE_L - BLACK_L, WHITE_L,
                     -0.004, BLACK_H, ebony, bevel=0.0009,
                     origin=(b, PIVOT_Y, 0), taper_top=0.0016, front_slope=0.006)
        else:
            i = white_index(m)
            cx = (i + 0.5) * PITCH
            ob = box(f'key_{m}', cx - WHITE_W / 2, cx + WHITE_W / 2, 0.0, WHITE_L,
                     -WHITE_T, 0.0, ivory, bevel=0.0011, origin=(cx, PIVOT_Y, 0))
        ob['midi'] = m

    box('key_slip', -0.058, SPAN + 0.058, -0.016, -0.001, -0.032, -0.007, lacquer, bevel=0.002)
    box('cheek_l', -0.058, -0.003, -0.017, 0.175, -0.032, 0.022, lacquer, bevel=0.004)
    box('cheek_r', SPAN + 0.003, SPAN + 0.058, -0.017, 0.175, -0.032, 0.022, lacquer, bevel=0.004)
    box('felt', -0.003, SPAN + 0.003, WHITE_L + 0.001, WHITE_L + 0.010, -0.006, 0.006, felt, bevel=0.001)
    board = box('name_board', -0.058, SPAN + 0.058, WHITE_L + 0.010, WHITE_L + 0.026, -0.010, 0.054, lacquer,
                bevel=0.003, origin=(SPAN / 2, WHITE_L + 0.018, -0.010))
    board.rotation_euler.x = math.radians(-BOARD_TILT)

    # The decal sits over the stage octave: the C4 to C5 span is centred on the F4|G4 boundary,
    # which is also the centre of the 61 keys.
    font_path = os.path.join(HERE, '..', '..', '..', 'assets', 'fonts', 'CormorantGaramond.ttf')
    cu = bpy.data.curves.new('decal', 'FONT')
    cu.body = 'Piano Tool'
    cu.font = bpy.data.fonts.load(os.path.abspath(font_path), check_existing=True)
    cu.align_x = 'CENTER'
    cu.align_y = 'CENTER'
    cu.size = 0.019
    cu.space_character = 1.06
    decal = bpy.data.objects.new('decal', cu)
    decal.data.materials.append(nickel)
    scene.collection.objects.link(decal)
    bpy.context.view_layer.update()

    # The maker's lockup: the brand mark, then the name, centred together.
    mark = mark_mesh('decal_mark', nickel, height=cu.size * 0.94)
    gap = cu.size * 0.3
    lockup = mark.dimensions.x + gap + decal.dimensions.x
    t = math.radians(BOARD_TILT)
    zc = 0.043
    y = WHITE_L + 0.0098 + zc * math.sin(t) - 0.0004 * math.cos(t)
    z = -0.010 + zc * math.cos(t) + 0.0004 * math.sin(t)
    left = SPAN / 2 - lockup / 2
    decal.location = (left + mark.dimensions.x + gap + decal.dimensions.x / 2, y, z)
    # The mark's origin is its visual centre; lift it a touch so the notehead sits on the baseline.
    mark.location = (left + mark.dimensions.x / 2, y - 0.0012 * math.sin(t), z + 0.0012 * math.cos(t))
    for ob in (decal, mark):
        ob.rotation_euler.x = math.radians(90 - BOARD_TILT)

    # Light: a soft warm key from above the player's head, a cool rim behind, a dark room.
    def area(name, loc, rot, size, energy, color, shape='RECTANGLE', size_y=None):
        ld = bpy.data.lights.new(name, 'AREA')
        ld.energy = energy
        ld.color = color
        ld.shape = shape
        ld.size = size
        ld.size_y = size_y or size
        lo = bpy.data.objects.new(name, ld)
        lo.location = loc
        lo.rotation_euler = rot
        scene.collection.objects.link(lo)
        return lo

    area('key_light', (SPAN * 0.45, 0.02, 0.75), (math.radians(4), 0, 0), 1.2, 95,
         (1.0, 0.89, 0.78), size_y=0.35)
    area('rim_light', (SPAN * 0.6, 0.7, 0.30), (math.radians(-65), 0, 0), 1.6, 22,
         (0.80, 0.86, 1.0), size_y=0.2)
    area('fill_card', (SPAN * 0.5, -0.9, 0.05), (math.radians(90), 0, 0), 2.4, 1.5, (1, 1, 1), size_y=0.12)

    world = scene.world or bpy.data.worlds.new('World')
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes['Background'].inputs['Color'].default_value = (0.004, 0.004, 0.005, 1)

    cam_data = bpy.data.cameras.new('cam')
    cam_data.type = 'ORTHO'
    cam_data.ortho_scale = SPAN + 0.13
    cam = bpy.data.objects.new('cam', cam_data)
    cam.rotation_euler = (math.radians(70), 0, 0)
    d = 1.2
    cam.location = (SPAN / 2, 0.075 - d * math.sin(math.radians(70)), 0.0 + d * math.cos(math.radians(70)))
    scene.collection.objects.link(cam)
    scene.camera = cam

    r = scene.render
    r.engine = 'CYCLES'
    scene.cycles.device = 'GPU'
    scene.cycles.samples = 192
    scene.cycles.use_denoising = True
    scene.cycles.seed = 7
    r.film_transparent = True
    r.image_settings.file_format = 'PNG'
    r.image_settings.color_mode = 'RGBA'
    r.resolution_x = 4320
    r.resolution_percentage = 100
    fit_frame()


def projected(ob):
    scene = bpy.context.scene
    dg = bpy.context.evaluated_depsgraph_get()
    ev = ob.evaluated_get(dg)
    pts = [world_to_camera_view(scene, scene.camera, ev.matrix_world @ v.co) for v in ev.data.vertices] \
        if ob.type == 'MESH' else []
    return pts


def fit_frame():
    """Set resolution_y and shift_y so the whole instrument fits with a small margin."""
    scene = bpy.context.scene
    cam = scene.camera
    scene.render.resolution_y = 1200
    cam.data.shift_y = 0
    bpy.context.view_layer.update()
    vs = []
    for ob in bpy.data.objects:
        if ob.type == 'MESH':
            vs += [p.y for p in projected(ob)]
    lo, hi = min(vs), max(vs)
    margin = 0.012
    frac = (hi - lo) + 2 * margin
    aspect_h = scene.render.resolution_y / scene.render.resolution_x
    # ortho_scale covers the larger dimension (x here): the visible height in scene units is
    # ortho_scale * aspect_h, and v runs 0..1 over it.
    new_h = int(round(scene.render.resolution_y * frac / 2) * 2)
    centre = (lo + hi) / 2
    cam.data.shift_y = (centre - 0.5) * aspect_h
    scene.render.resolution_y = new_h
    bpy.context.view_layer.update()


def set_pressed(midi=None):
    for ob in bpy.data.objects:
        if 'midi' in ob:
            ob.rotation_euler.x = math.atan(DIP / PIVOT_Y) if ob['midi'] == midi else 0.0
    bpy.context.view_layer.update()


def key_geometry():
    """Rest-state bounding box of every key in image space, top-left origin, 0..1."""
    set_pressed(None)
    scene = bpy.context.scene
    keys = []
    for ob in sorted((o for o in bpy.data.objects if 'midi' in o), key=lambda o: o['midi']):
        pts = projected(ob)
        xs = [p.x for p in pts]
        ys = [1 - p.y for p in pts]
        keys.append({'midi': ob['midi'], 'black': is_black(ob['midi']),
                     'x0': round(min(xs), 5), 'x1': round(max(xs), 5),
                     'y0': round(min(ys), 5), 'y1': round(max(ys), 5)})
    return {'width': scene.render.resolution_x, 'height': scene.render.resolution_y, 'keys': keys}


def render(path, border=None):
    r = bpy.context.scene.render
    if border:
        r.use_border = True
        r.use_crop_to_border = True
        r.border_min_x, r.border_max_x = border
        r.border_min_y, r.border_max_y = 0.0, 1.0
    else:
        r.use_border = False
        r.use_crop_to_border = False
    r.filepath = path
    bpy.ops.render.render(write_still=True)


def crop_for(geom, midi):
    """Horizontal crop around a key: the key plus a third of a white key each side, so the
    neighbours' exposed sides are inside the crop."""
    k = next(k for k in geom['keys'] if k['midi'] == midi)
    pad = (PITCH / (SPAN + 0.13)) * 0.6
    x0 = max(0.0, k['x0'] - pad)
    x1 = min(1.0, k['x1'] + pad)
    px = geom['width']
    x0 = math.floor(x0 * px / 2) * 2 / px
    x1 = math.ceil(x1 * px / 2) * 2 / px
    return x0, x1
