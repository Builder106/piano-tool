# Builds the music desk the sheet stands on, then renders two images for the site:
#   ledge.png  the ledge at the foot of the desk, with the groove the sheet stands in
#   paper.png  a 512 px tileable paper grain, cool and fine
# render_desk() also renders the panel itself (desk.png); the site does not use it, because
# the lacquer's reflections read as grey bands that compete with the sheet.
# Run headless: blender -b -P desk.py -- <out_dir>
# Materials and lights follow keyboard.py so the desk and the keys read as one instrument.
import math
import os
import sys

import bpy
import numpy as np

OUT = sys.argv[sys.argv.index('--') + 1] if '--' in sys.argv else os.path.dirname(os.path.abspath(__file__))
W = 1.20          # desk width, metres
H = 0.42          # desk panel height
TILT = 12         # degrees back from vertical
LEDGE_D = 0.034   # ledge depth
LEDGE_H = 0.016   # ledge front face height
GROOVE = 0.006


def material(name, color, rough, **extra):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    p = mat.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = (*color, 1)
    p.inputs['Roughness'].default_value = rough
    for k, v in extra.items():
        p.inputs[k].default_value = v
    return mat


def cube(name, size, loc, mat, bevel=0.002, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    ob = bpy.context.active_object
    ob.name = name
    ob.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    ob.data.materials.append(mat)
    if bevel:
        m = ob.modifiers.new('bevel', 'BEVEL')
        m.width = bevel
        m.segments = 4
    bpy.ops.object.shade_smooth()
    return ob


def area(name, loc, rot, size, energy, color, size_y=None):
    ld = bpy.data.lights.new(name, 'AREA')
    ld.energy = energy
    ld.color = color
    ld.shape = 'RECTANGLE'
    ld.size = size
    ld.size_y = size_y or size
    lo = bpy.data.objects.new(name, ld)
    lo.location = loc
    lo.rotation_euler = rot
    bpy.context.scene.collection.objects.link(lo)
    return lo


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    lacquer = material('lacquer', (0.006, 0.006, 0.007), 0.06, **{'Coat Weight': 1.0, 'Coat Roughness': 0.02})
    felt = material('felt', (0.022, 0.0025, 0.0035), 1.0, **{'Sheen Weight': 0.3})

    # The panel leans back from its foot at the origin.
    t = math.radians(TILT)
    panel = cube('panel', (W, 0.018, H), (0, 0.009 + math.sin(t) * H / 2, math.cos(t) * H / 2), lacquer,
                 bevel=0.004, rot=(-t, 0, 0))
    # Ledge: a lip in front of the panel's foot, with a groove between lip and panel.
    lip = cube('ledge_lip', (W + 0.02, 0.012, LEDGE_H), (0, -LEDGE_D + 0.006, LEDGE_H / 2 - 0.004), lacquer, bevel=0.0025)
    floor = cube('ledge_floor', (W + 0.02, LEDGE_D, 0.008), (0, -LEDGE_D / 2, -0.004), lacquer, bevel=0.0015)
    strip = cube('groove_felt', (W, GROOVE * 2, 0.002), (0, -GROOVE - 0.002, 0.0012), felt, bevel=0)
    for ob in (lip, floor, strip):
        ob['ledge'] = True
    panel['panel'] = True

    # A soft warm key from above the player's head, as on the keys, and a long card behind the
    # player that the lacquer mirrors as a faint band near the top of the desk.
    area('key_light', (0, -0.55, 0.95), (math.radians(38), 0, 0), 1.4, 22, (1.0, 0.89, 0.78), size_y=0.35)
    area('mirror_card', (0, -1.6, 0.62), (math.radians(90), 0, 0), 2.6, 0.8, (0.85, 0.9, 1.0), size_y=0.45)
    area('rim_light', (0, 0.6, 0.6), (math.radians(-60), 0, 0), 1.6, 10, (0.8, 0.86, 1.0), size_y=0.2)

    world = bpy.data.worlds.new('World')
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes['Background'].inputs['Color'].default_value = (0.004, 0.004, 0.005, 1)

    cam_data = bpy.data.cameras.new('cam')
    cam_data.type = 'ORTHO'
    cam = bpy.data.objects.new('cam', cam_data)
    # Eye level a little above the ledge, looking straight at the desk: the view from the bench.
    cam.rotation_euler = (math.radians(84), 0, 0)
    cam.location = (0, -1.4, 0.22)
    scene.collection.objects.link(cam)
    scene.camera = cam

    r = scene.render
    r.engine = 'CYCLES'
    scene.cycles.device = 'GPU'
    scene.cycles.samples = 160
    scene.cycles.use_denoising = True
    scene.cycles.seed = 11
    r.image_settings.file_format = 'PNG'
    r.image_settings.color_mode = 'RGBA'
    r.resolution_percentage = 100
    prefs = bpy.context.preferences.addons['cycles'].preferences
    try:
        prefs.compute_device_type = 'METAL'
        prefs.get_devices()
        for d in prefs.devices:
            d.use = True
    except Exception:
        scene.cycles.device = 'CPU'


def show(key):
    for ob in bpy.data.objects:
        if ob.type == 'MESH':
            ob.hide_render = key not in ob
    bpy.context.view_layer.update()


def render_desk():
    scene = bpy.context.scene
    show('panel')
    scene.render.film_transparent = False
    scene.render.resolution_x = 2880
    scene.render.resolution_y = 1100
    # Level view, framed inside the panel so it fills the image edge to edge.
    scene.camera.rotation_euler.x = math.radians(90)
    scene.camera.data.ortho_scale = 0.38 / (1100 / 2880)
    scene.camera.location.z = math.cos(math.radians(TILT)) * H / 2
    scene.render.filepath = os.path.join(OUT, 'desk.png')
    bpy.ops.render.render(write_still=True)


def render_ledge():
    scene = bpy.context.scene
    show('ledge')
    scene.render.film_transparent = True
    scene.render.resolution_x = 4320
    scene.render.resolution_y = 160
    scene.camera.data.ortho_scale = W
    # Looking down 10 degrees so the groove shows; the view axis passes through the lip.
    down = math.radians(10)
    scene.camera.rotation_euler.x = math.pi / 2 - down
    scene.camera.location.y = -1.4
    scene.camera.location.z = 0.004 + (1.4 - LEDGE_D) * math.tan(down)
    scene.render.filepath = os.path.join(OUT, 'ledge.png')
    bpy.ops.render.render(write_still=True)


def paper_grain(size=512):
    """Tileable fibre grain: white noise shaped in the frequency domain (so it wraps), with a
    1/f falloff and fibres stretched along x, mapped into a narrow cool-white range around
    #ECEEF1."""
    rng = np.random.default_rng(3)
    fx = np.fft.fftfreq(size)[None, :]
    fy = np.fft.fftfreq(size)[:, None]
    f = np.sqrt((fx * 2.5) ** 2 + fy ** 2) + 1 / size
    spectrum = np.fft.fft2(rng.standard_normal((size, size))) / f ** 0.9
    acc = np.real(np.fft.ifft2(spectrum))
    acc = (acc - acc.mean()) / (acc.std() + 1e-9)
    base = np.array([0xEC, 0xEE, 0xF1]) / 255.0
    rgb = np.clip(base[None, None, :] + acc[..., None] * 0.012, 0, 1)
    rgba = np.concatenate([rgb, np.ones((size, size, 1))], axis=2)
    img = bpy.data.images.new('paper', size, size, alpha=True)
    img.pixels = rgba[::-1].astype(np.float32).ravel()
    img.filepath_raw = os.path.join(OUT, 'paper.png')
    img.file_format = 'PNG'
    img.save()


build()
render_ledge()
paper_grain()
