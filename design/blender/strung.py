# Look-development scene for the "Strung" app design (see DESIGN.md): an open
# grand seen from the player's seat. The keys, cheeks and name board come from
# the site's keyboard (site/design/blender/keyboard.py); this file adds the
# dampers, the strings and the soundboard behind them.
#
# Run headless on a Mac with a GPU:
#   PIANO_FONT=<AtkinsonWordmark.ttf> Blender -b --factory-startup \
#     -P design/blender/strung.py -- <output dir>
#
# Units are metres. x runs across the keyboard, y away from the player.
import math
import os
import sys

import bpy
import mathutils

OUT = sys.argv[sys.argv.index('--') + 1] if '--' in sys.argv else os.getcwd()
os.makedirs(OUT, exist_ok=True)
HERE = os.path.dirname(os.path.abspath(__file__))
KEYBOARD = os.path.join(HERE, '..', '..', 'site', 'design', 'blender', 'keyboard.py')

src = open(KEYBOARD).read()
src = src.replace(
    "HERE = os.path.dirname(os.path.abspath(__file__)) if '__file__' in dir() else ''",
    f"HERE = {os.path.dirname(os.path.abspath(KEYBOARD))!r}")
src = src.replace(
    "font_path = os.path.join(HERE, '..', '..', '..', 'assets', 'fonts', 'AtkinsonWordmark.ttf')",
    "font_path = os.environ['PIANO_FONT']")
exec(compile(src, KEYBOARD, 'exec'))  # defines build(), material(), box(), LOWEST, SPAN, ...

NOTE_W = SPAN / (HIGHEST - LOWEST + 1)
UNISON = (-0.0032, 0.0, 0.0032)
STRING_R = 0.00045
STRING_Z = 0.020
VIEW_TILT = 40          # degrees from straight down
VIEW_W = 0.50           # metres of keyboard across the frame
MIDDLE_C_X = (60 - LOWEST + 0.5) * NOTE_W


def note_x(m):
    return (m - LOWEST + 0.5) * NOTE_W


def string(name, points, radius, mat):
    cu = bpy.data.curves.new(name, 'CURVE')
    cu.dimensions = '3D'
    cu.bevel_depth = radius
    cu.bevel_resolution = 6
    sp = cu.splines.new('POLY')
    sp.points.add(len(points) - 1)
    for pt, co in zip(sp.points, points):
        pt.co = (*co, 1)
    ob = bpy.data.objects.new(name, cu)
    bpy.context.scene.collection.objects.link(ob)
    ob.data.materials.append(mat)
    return ob


def node(nt, kind, **inputs):
    n = nt.nodes.new(kind)
    for k, v in inputs.items():
        n.inputs[k].default_value = v
    return n


def grain(mat, scale, strength):
    nt = mat.node_tree
    p = nt.nodes['Principled BSDF']
    coord = nt.nodes.new('ShaderNodeTexCoord')
    mapping = node(nt, 'ShaderNodeMapping', Scale=(40, 1, 1))
    noise = node(nt, 'ShaderNodeTexNoise', Scale=scale, Detail=6)
    bump = node(nt, 'ShaderNodeBump', Strength=strength)
    nt.links.new(coord.outputs['Object'], mapping.inputs['Vector'])
    nt.links.new(mapping.outputs['Vector'], noise.inputs['Vector'])
    nt.links.new(noise.outputs['Fac'], bump.inputs['Height'])
    nt.links.new(bump.outputs['Normal'], p.inputs['Normal'])


def glints(mat, lo, hi):
    """Roughness that drifts along the string, so highlights break into glints."""
    nt = mat.node_tree
    p = nt.nodes['Principled BSDF']
    coord = nt.nodes.new('ShaderNodeTexCoord')
    mapping = node(nt, 'ShaderNodeMapping', Scale=(300, 6, 300))
    noise = node(nt, 'ShaderNodeTexNoise', Scale=4.0, Detail=3)
    ramp = nt.nodes.new('ShaderNodeMapRange')
    ramp.inputs['To Min'].default_value = lo
    ramp.inputs['To Max'].default_value = hi
    nt.links.new(coord.outputs['Object'], mapping.inputs['Vector'])
    nt.links.new(mapping.outputs['Vector'], noise.inputs['Vector'])
    nt.links.new(noise.outputs['Fac'], ramp.inputs['Value'])
    nt.links.new(ramp.outputs['Result'], p.inputs['Roughness'])


def winding(mat):
    """Copper wrap: fine bands across the string."""
    nt = mat.node_tree
    p = nt.nodes['Principled BSDF']
    coord = nt.nodes.new('ShaderNodeTexCoord')
    wave = nt.nodes.new('ShaderNodeTexWave')
    wave.wave_type = 'BANDS'
    wave.bands_direction = 'Y'
    wave.inputs['Scale'].default_value = 520
    bump = node(nt, 'ShaderNodeBump', Strength=1.0, Distance=0.0004)
    nt.links.new(coord.outputs['Object'], wave.inputs['Vector'])
    nt.links.new(wave.outputs['Fac'], bump.inputs['Height'])
    nt.links.new(bump.outputs['Normal'], p.inputs['Normal'])


BASS_TOP = LOWEST + 11          # C2 to B2 are copper-wound and cross over the tenor
BASS_ANGLE = math.radians(13)   # the overstrung fan, seen from the player
BREAK_GAP = 0.010               # room for the plate bar between bass and tenor
DAMPER_TOP = STRING_Z + 0.019   # one level for the whole row, whatever string it rests on


def strings_and_dampers():
    steel = material('steel', (0.82, 0.84, 0.88), 0.16, **{'Metallic': 1.0})
    glints(steel, 0.08, 0.32)
    copper = material('copper', (0.78, 0.38, 0.20), 0.3, **{'Metallic': 1.0})
    winding(copper)
    glints(copper, 0.22, 0.42)
    plate = material('plate', (0.045, 0.048, 0.056), 0.5, **{'Metallic': 0.35})
    damper = material('damper', (0.012, 0.012, 0.014), 0.38, **{'Coat Weight': 0.3})
    felt = material('damper_felt', (0.50, 0.52, 0.56), 1.0, **{'Sheen Weight': 0.6})
    spruce = material('soundboard', (0.055, 0.038, 0.025), 0.6)
    grain(spruce, 60, 0.35)
    maple = material('bridge', (0.075, 0.042, 0.024), 0.55)

    x0, x1 = -0.06, SPAN + 0.06
    back = WHITE_L + 0.026
    far = 1.4
    box('soundboard', x0, x1, back, far, -0.020, -0.016, spruce, bevel=0)
    # The plate's front edge hides the tuning pins; only the strings leave it,
    # each note through an agraffe.
    box('plate_front', x0, x1, back, back + 0.030, -0.016, STRING_Z - 0.002, plate, bevel=0.002)

    break_x = note_x(BASS_TOP) + NOTE_W / 2 + BREAK_GAP / 2
    box('plate_bar', break_x - 0.006, break_x + 0.006, back, far, STRING_Z - 0.004, STRING_Z + 0.005,
        plate, bevel=0.003)

    bridge_y = back + 0.205
    box('bridge', break_x + 0.008, x1, bridge_y, bridge_y + 0.012, -0.016, STRING_Z - STRING_R - 0.0002,
        maple, bevel=0.002)

    for m in range(LOWEST, HIGHEST + 1):
        bass = m <= BASS_TOP
        cx = note_x(m) + (0 if bass else BREAK_GAP)
        if bass:
            # Bichords of wound copper, raised to cross over the tenor strings.
            z = STRING_Z + 0.007
            run = far - back
            for i, off in enumerate((-0.0022, 0.0022)):
                xa = cx + off
                string(f'string_{m}_{i}', [(xa, back + 0.005, z), (xa + run * math.tan(BASS_ANGLE), far, z)],
                       0.0014, copper)
        else:
            r = 0.00055 if m < 72 else 0.00045
            for i, off in enumerate(UNISON):
                xa = cx + off
                # Each string bends round two bridge pins, one behind the other.
                jog = 0.0012
                pts = [(xa, back + 0.005, STRING_Z), (xa, bridge_y + 0.004, STRING_Z),
                       (xa + jog, bridge_y + 0.012, STRING_Z), (xa + jog, far, STRING_Z)]
                string(f'string_{m}_{i}', pts, r, steel)
                cylinder_pin(f'bridge_pin_{m}_{i}a', xa - 0.0009, bridge_y + 0.004, steel)
                cylinder_pin(f'bridge_pin_{m}_{i}b', xa + jog + 0.0009, bridge_y + 0.012, steel)
            box(f'agraffe_{m}', cx - 0.0050, cx + 0.0050, back + 0.022, back + 0.028,
                STRING_Z - 0.003, STRING_Z + 0.0015, steel, bevel=0.0008)
        if m < HIGHEST - 12:   # dampers stop below the top octave, as on a grand
            rest = STRING_Z + (0.007 + 0.0014 if bass else STRING_R)
            box(f'damper_felt_{m}', cx - 0.0058, cx + 0.0058, back + 0.040, back + 0.064,
                rest, rest + 0.0012, felt, bevel=0.0003)
            box(f'damper_{m}', cx - 0.0054, cx + 0.0054, back + 0.0415, back + 0.0625,
                rest + 0.0012, DAMPER_TOP, damper, bevel=0.0008)


def cylinder_pin(name, x, y, mat):
    bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=0.0006, depth=0.004,
                                        location=(x, y, STRING_Z - 0.001))
    ob = bpy.context.object
    ob.name = name
    ob.data.materials.append(mat)


def frame():
    scene = bpy.context.scene
    for ob in [o for o in bpy.data.objects if o.type == 'CAMERA']:
        bpy.data.objects.remove(ob, do_unlink=True)
    cam_data = bpy.data.cameras.new('seat')
    cam_data.type = 'ORTHO'
    cam_data.ortho_scale = VIEW_W
    cam = bpy.data.objects.new('seat', cam_data)
    t = math.radians(VIEW_TILT)
    target = (MIDDLE_C_X, WHITE_L + 0.09, 0.0)
    d = 1.5
    cam.location = (target[0], target[1] - d * math.sin(t), target[2] + d * math.cos(t))
    cam.rotation_euler = (t, 0, 0)
    scene.collection.objects.link(cam)
    scene.camera = cam

    # A light over the strings, behind the player's line of sight, so they glint.
    ld = bpy.data.lights.new('string_glint', 'AREA')
    ld.energy = 2
    ld.size = 0.8
    ld.size_y = 0.15
    ld.color = (1.0, 0.93, 0.85)
    lo = bpy.data.objects.new('string_glint', ld)
    lo.location = (MIDDLE_C_X, 0.55, 0.45)
    lo.rotation_euler = (math.radians(-35), 0, 0)
    scene.collection.objects.link(lo)

    # The site's name board leans back to mirror the room from a low camera; from
    # this higher seat it would mirror the keys, so give it a satin finish here.
    satin = material('name_board_satin', (0.008, 0.008, 0.009), 0.32, **{'Coat Weight': 0.0})
    bpy.data.objects['name_board'].data.materials[0] = satin

    # A low sun from the front left, so each string throws a thin shadow on the
    # soundboard below it.
    sun_data = bpy.data.lights.new('sun', 'SUN')
    sun_data.energy = 5.0
    bpy.data.objects['key_light'].data.energy = 60
    sun_data.angle = math.radians(1.5)
    sun_data.color = (1.0, 0.92, 0.82)
    sun = bpy.data.objects.new('sun', sun_data)
    sun.rotation_euler = (math.radians(38), math.radians(-22), 0)
    scene.collection.objects.link(sun)

    r = scene.render
    r.film_transparent = False
    r.resolution_x = 1920
    r.resolution_y = 1080
    r.resolution_percentage = 100
    r.use_border = False
    scene.view_settings.view_transform = 'AgX'
    scene.view_settings.look = 'AgX - Medium High Contrast'
    scene.view_settings.exposure = -1.1
    prefs = bpy.context.preferences.addons['cycles'].preferences
    prefs.compute_device_type = 'METAL'
    prefs.get_devices()
    for dev in prefs.devices:
        dev.use = True
    scene.cycles.device = 'GPU'
    scene.cycles.samples = 128


def to_image(co):
    """World point to image coordinates, 0..1 with a top-left origin."""
    scene = bpy.context.scene
    p = world_to_camera_view(scene, scene.camera, mathutils.Vector(co))
    return round(p.x, 5), round(1 - p.y, 5)


def image_box(objects):
    """Image-space bounds of objects (meshes, curves or text), from their
    evaluated bounding boxes."""
    dg = bpy.context.evaluated_depsgraph_get()
    pts = []
    for ob in objects:
        ev = ob.evaluated_get(dg)
        pts += [to_image(ev.matrix_world @ mathutils.Vector(c)) for c in ev.bound_box]
    return {'x0': min(p[0] for p in pts), 'x1': max(p[0] for p in pts),
            'y0': min(p[1] for p in pts), 'y1': max(p[1] for p in pts)}


SLIP_W = 0.0875          # a paper slip resting on the strings, metres
SLIP_D = 0.0316
SLIP_PX = 896            # slip width in the asset, pixels
SLIP_IMAGE = (960, 320)  # asset size; the margin holds the slip's shadow


def slip():
    """Render one paper slip lying on the strings, alone on a transparent
    ground with its own contact shadow, in the scene's light and camera tilt.
    The app draws the lettering on it."""
    scene = bpy.context.scene
    back = WHITE_L + 0.026
    cx, cy = MIDDLE_C_X, back + 0.13
    z = STRING_Z + STRING_R + 0.0003

    paper = material('slip_paper', (0.62, 0.63, 0.66), 0.85, **{'Subsurface Weight': 0.05})
    nt = paper.node_tree
    pb = nt.nodes['Principled BSDF']
    coord = nt.nodes.new('ShaderNodeTexCoord')
    fibres = node(nt, 'ShaderNodeTexNoise', Scale=2400.0, Detail=4)
    tone = node(nt, 'ShaderNodeTexNoise', Scale=60.0, Detail=2)
    bump = node(nt, 'ShaderNodeBump', Strength=0.3, Distance=0.0002)
    mix = nt.nodes.new('ShaderNodeMix')
    mix.data_type = 'RGBA'
    mix.inputs['Factor'].default_value = 0.0
    mix.inputs['A'].default_value = (0.62, 0.63, 0.66, 1)
    mix.inputs['B'].default_value = (0.55, 0.56, 0.60, 1)
    ramp = nt.nodes.new('ShaderNodeMapRange')
    ramp.inputs['To Min'].default_value = 0.0
    ramp.inputs['To Max'].default_value = 0.5
    for a, b in ((coord.outputs['Object'], fibres.inputs['Vector']),
                 (coord.outputs['Object'], tone.inputs['Vector']),
                 (fibres.outputs['Fac'], bump.inputs['Height']),
                 (bump.outputs['Normal'], pb.inputs['Normal']),
                 (tone.outputs['Fac'], ramp.inputs['Value']),
                 (ramp.outputs['Result'], mix.inputs['Factor']),
                 (mix.outputs['Result'], pb.inputs['Base Color'])):
        nt.links.new(a, b)

    bpy.ops.mesh.primitive_grid_add(x_subdivisions=48, y_subdivisions=12, size=1,
                                    location=(cx, cy, z))
    ob = bpy.context.object
    ob.name = 'slip'
    ob.scale = (SLIP_W, SLIP_D, 1)
    bpy.ops.object.transform_apply(scale=True)
    mid = sum(v.co.x for v in ob.data.vertices) / len(ob.data.vertices)
    for v in ob.data.vertices:
        # The ends lift off the strings a little, as card stock does.
        t = ((v.co.x - mid) / (SLIP_W / 2)) ** 2
        v.co.z += 0.0012 * t
    ob.data.materials.append(paper)
    bpy.ops.object.shade_smooth()
    solid = ob.modifiers.new('thickness', 'SOLIDIFY')
    solid.thickness = 0.00018

    bpy.ops.mesh.primitive_plane_add(size=1, location=(cx, cy, z - 0.0006))
    catcher = bpy.context.object
    catcher.name = 'slip_shadow'
    catcher.scale = (SLIP_W * 1.3, SLIP_D * 2.2, 1)
    catcher.is_shadow_catcher = True

    keep = {'slip', 'slip_shadow'}
    for o in bpy.data.objects:
        if o.type in {'MESH', 'CURVE', 'FONT'} and o.name not in keep:
            o.hide_render = True

    cam = scene.camera
    t = math.radians(VIEW_TILT)
    d = 1.5
    cam.location = (cx, cy - d * math.sin(t), z + d * math.cos(t))
    cam.data.ortho_scale = SLIP_W * SLIP_IMAGE[0] / SLIP_PX
    r = scene.render
    r.resolution_x, r.resolution_y = SLIP_IMAGE
    r.film_transparent = True
    r.image_settings.color_mode = 'RGBA'
    render(os.path.join(OUT, 'strung-slip.png'))


def soundboard():
    """Render the bare soundboard from above, grain running across the frame,
    as the ground the practice staff is strung over."""
    scene = bpy.context.scene
    for o in bpy.data.objects:
        if o.type in {'MESH', 'CURVE', 'FONT'} and o.name != 'soundboard':
            o.hide_render = True
    cam = scene.camera
    back = WHITE_L + 0.026
    cam.rotation_euler = (0, 0, math.radians(90))
    cam.location = (MIDDLE_C_X, back + 0.30, 0.6)
    cam.data.ortho_scale = 0.40
    r = scene.render
    r.resolution_x, r.resolution_y = 1920, 1080
    r.film_transparent = False
    r.image_settings.file_format = 'JPEG'
    r.image_settings.quality = 88
    render(os.path.join(OUT, 'strung-soundboard.jpg'))


METRO_IMAGE = (600, 800)
METRO_PIVOT_Z = 0.045     # rod pivot above the base, metres
METRO_ROD = 0.19          # rod length above the pivot
METRO_WEIGHT_AT = 0.10    # where the weight sits in its render


def metronome():
    """Render a metronome as three sprites from one camera: the body with its
    tempo scale, the rod, and the sliding weight. The app swings the rod
    about its pivot and slides the weight along it, so the pivot, the rod's
    top and the weight's centre are exported with the renders."""
    import json
    scene = bpy.context.scene
    for o in bpy.data.objects:
        if o.type in {'MESH', 'CURVE', 'FONT', 'LIGHT'}:
            o.hide_render = True
    ox = 3.0   # well away from the piano
    lacquer = material('metro_lacquer', (0.012, 0.012, 0.014), 0.22, **{'Coat Weight': 0.8, 'Coat Roughness': 0.08})
    nickel = material('metro_nickel', (0.72, 0.74, 0.77), 0.25, **{'Metallic': 1.0})
    steel = material('metro_steel', (0.82, 0.84, 0.88), 0.18, **{'Metallic': 1.0})
    scale_plate = material('metro_scale', (0.62, 0.63, 0.66), 0.35, **{'Metallic': 0.6})

    def frustum(name, w0, d0, w1, d1, z0, z1, mat):
        me = bpy.data.meshes.new(name)
        bm = bmesh.new()
        lo = [bm.verts.new((ox + x * w0 / 2, y * d0 / 2, z0)) for x, y in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
        hi = [bm.verts.new((ox + x * w1 / 2, y * d1 / 2, z1)) for x, y in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
        bm.faces.new(lo[::-1])
        bm.faces.new(hi)
        for i in range(4):
            bm.faces.new((lo[i], lo[(i + 1) % 4], hi[(i + 1) % 4], hi[i]))
        bm.to_mesh(me)
        bm.free()
        ob = bpy.data.objects.new(name, me)
        bpy.context.scene.collection.objects.link(ob)
        ob.data.materials.append(mat)
        mod = ob.modifiers.new('bevel', 'BEVEL')
        mod.width = 0.0015
        mod.segments = 3
        return ob

    body = [
        box('metro_plinth', ox - 0.068, ox + 0.068, -0.048, 0.048, 0.0, 0.016, lacquer, bevel=0.003),
        frustum('metro_body', 0.112, 0.074, 0.036, 0.030, 0.016, 0.235, lacquer),
        box('metro_scale', ox - 0.012, ox + 0.012, -0.0262, -0.0255, 0.06, 0.205, scale_plate, bevel=0.0004),
    ]
    # Tick marks on the scale, nickel on the plate.
    for i in range(14):
        z = 0.068 + i * 0.0098
        w = 0.008 if i % 2 == 0 else 0.005
        body.append(box(f'metro_tick_{i}', ox - w, ox + w, -0.0270, -0.0262, z, z + 0.0009, nickel))
    pivot = (ox, -0.034, METRO_PIVOT_Z)
    rod_data = bpy.data.curves.new('metro_rod', 'CURVE')
    rod_data.dimensions = '3D'
    rod_data.bevel_depth = 0.0011
    rod_data.bevel_resolution = 6
    sp = rod_data.splines.new('POLY')
    sp.points.add(1)
    sp.points[0].co = (*pivot, 1)
    sp.points[1].co = (pivot[0], pivot[1], pivot[2] + METRO_ROD, 1)
    rod = bpy.data.objects.new('metro_rod', rod_data)
    scene.collection.objects.link(rod)
    rod.data.materials.append(steel)
    wz = pivot[2] + METRO_WEIGHT_AT
    weight = frustum('metro_weight', 0.020, 0.010, 0.013, 0.008, wz - 0.009, wz + 0.009, nickel)
    weight.location.y = pivot[1]

    def area(name, loc, size, energy, color=(1, 1, 1)):
        data = bpy.data.lights.new(name, 'AREA')
        data.size = size
        data.energy = energy
        data.color = color
        ob = bpy.data.objects.new(name, data)
        scene.collection.objects.link(ob)
        ob.location = loc
        target = mathutils.Vector((ox, 0, 0.12))
        ob.rotation_euler = (target - ob.location).to_track_quat('-Z', 'Y').to_euler()
        return ob

    area('metro_key', (ox - 0.35, -0.55, 0.55), 0.6, 9, (1.0, 0.92, 0.84))
    area('metro_rim', (ox + 0.4, 0.4, 0.45), 0.5, 6, (0.85, 0.9, 1.0))
    area('metro_fill', (ox + 0.3, -0.6, 0.1), 0.6, 2.5)

    cam = scene.camera
    tilt = math.radians(12)
    target = mathutils.Vector((ox, 0, 0.125))
    d = 2.0
    cam.location = target + mathutils.Vector((0, -d * math.cos(tilt), d * math.sin(tilt)))
    cam.rotation_euler = (math.radians(90) - tilt, 0, 0)
    cam.data.ortho_scale = 0.27
    r = scene.render
    r.resolution_x, r.resolution_y = METRO_IMAGE
    r.film_transparent = True
    r.image_settings.file_format = 'PNG'
    r.image_settings.color_mode = 'RGBA'
    bpy.context.view_layer.update()

    parts = {'body': body, 'rod': [rod], 'weight': [weight]}
    for name, shown in parts.items():
        for group in parts.values():
            for o in group:
                o.hide_render = o not in shown
        render(os.path.join(OUT, f'strung-metronome-{name}.png'))

    out = {
        'width': METRO_IMAGE[0], 'height': METRO_IMAGE[1],
        'pivot': to_image(pivot),
        'rodTop': to_image((pivot[0], pivot[1], pivot[2] + METRO_ROD)),
        'weight': to_image((pivot[0], pivot[1], wz)),
        'base': to_image((ox, -0.048, 0.0)),
    }
    with open(os.path.join(OUT, 'strung-metronome.json'), 'w') as f:
        json.dump(out, f, indent=1)


def geometry():
    """Where each note's strings, damper and key land in the image, so the app
    can draw lit strings and labels exactly over the render."""
    import json
    bpy.context.view_layer.update()
    back = WHITE_L + 0.026
    keys = {k['midi']: k for k in key_geometry()['keys']}
    notes = []
    for m in range(LOWEST, HIGHEST + 1):
        if m <= BASS_TOP:
            continue
        cx = note_x(m) + BREAK_GAP
        xs = [to_image((cx + off, back + 0.052, STRING_Z))[0] for off in UNISON]
        entry = {'midi': m, 'strings': xs, 'key': keys[m]}
        damper = bpy.data.objects.get(f'damper_{m}')
        if damper:
            pts = [to_image(damper.matrix_world @ v.co) for v in damper.data.vertices]
            entry['damper'] = {'x0': min(p[0] for p in pts), 'x1': max(p[0] for p in pts),
                               'y0': min(p[1] for p in pts), 'y1': max(p[1] for p in pts)}
        notes.append(entry)
    logo = image_box([bpy.data.objects['decal'], bpy.data.objects['decal_mark']])
    out = {'width': bpy.context.scene.render.resolution_x,
           'height': bpy.context.scene.render.resolution_y,
           'nameBoard': image_box([bpy.data.objects['name_board']]),
           'logo': logo, 'notes': notes}
    with open(os.path.join(OUT, 'strung-home.json'), 'w') as f:
        json.dump(out, f, indent=1)


build()
strings_and_dampers()
frame()
geometry()
if os.environ.get('STRUNG_GEOMETRY_ONLY'):
    raise SystemExit
if os.environ.get('STRUNG_SLIP'):
    slip()
    raise SystemExit
if os.environ.get('STRUNG_SOUNDBOARD'):
    soundboard()
    raise SystemExit
if os.environ.get('STRUNG_METRONOME'):
    metronome()
    raise SystemExit
render(os.path.join(OUT, 'strung-lookdev.png'))
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, 'strung-lookdev.blend'))
