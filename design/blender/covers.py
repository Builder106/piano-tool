# Renders the method-book covers the app shows for each stage: a cloth-bound board with a
# raised frame rule and a spine hinge, turned a little so the page block shows on the right.
# The title and stage number are set by the app over the blank cover, so imported pieces get
# one too. Run: Blender -b -P design/blender/covers.py  (writes assets/art/cover-*.png)
import math
import os

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'assets', 'art')

# Stage colours, from brand/README.md. Slate is the imported-piece cover.
COVERS = {
    'blue': '#2456C8',
    'green': '#1F6A50',
    'rust': '#B4501E',
    'slate': '#4E535C',
}

W, H, T = 0.21, 0.28, 0.0035   # board, metres
SPINE = 0.022                  # hinge groove sits this far in from the left edge
PAGES = 0.016                  # page block thickness behind the board


def linear(hex_colour):
    out = []
    for i in (1, 3, 5):
        c = int(hex_colour[i:i + 2], 16) / 255
        out.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    return (*out, 1.0)


def box(name, x0, x1, y0, y1, z0, z1, mat, bevel=0.0008):
    bpy.ops.mesh.primitive_cube_add(location=((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))
    ob = bpy.context.active_object
    ob.name = name
    ob.scale = ((x1 - x0) / 2, (y1 - y0) / 2, (z1 - z0) / 2)
    bpy.ops.object.transform_apply(scale=True)
    if bevel:
        mod = ob.modifiers.new('bevel', 'BEVEL')
        mod.width = bevel
        mod.segments = 3
    ob.data.materials.append(mat)
    return ob


def cloth(name):
    """Book cloth: a fine plain weave in the bump, a little sheen, slight dye variation."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes['Principled BSDF']
    bsdf.inputs['Roughness'].default_value = 0.82
    bsdf.inputs['Sheen Weight'].default_value = 0.15
    bsdf.inputs['Sheen Roughness'].default_value = 0.4

    coord = nt.nodes.new('ShaderNodeTexCoord')
    warp = nt.nodes.new('ShaderNodeTexWave')
    warp.wave_type = 'BANDS'
    warp.bands_direction = 'X'
    warp.inputs['Scale'].default_value = 900
    weft = nt.nodes.new('ShaderNodeTexWave')
    weft.wave_type = 'BANDS'
    weft.bands_direction = 'Y'
    weft.inputs['Scale'].default_value = 900
    for wave in (warp, weft):
        nt.links.new(coord.outputs['Object'], wave.inputs['Vector'])
    mix = nt.nodes.new('ShaderNodeMath')
    mix.operation = 'MULTIPLY'
    nt.links.new(warp.outputs['Fac'], mix.inputs[0])
    nt.links.new(weft.outputs['Fac'], mix.inputs[1])
    bump = nt.nodes.new('ShaderNodeBump')
    bump.inputs['Strength'].default_value = 0.55
    bump.inputs['Distance'].default_value = 0.0002
    nt.links.new(mix.outputs['Value'], bump.inputs['Height'])
    nt.links.new(bump.outputs['Normal'], bsdf.inputs['Normal'])

    noise = nt.nodes.new('ShaderNodeTexNoise')
    noise.inputs['Scale'].default_value = 60
    noise.inputs['Detail'].default_value = 6
    nt.links.new(coord.outputs['Object'], noise.inputs['Vector'])
    dye = nt.nodes.new('ShaderNodeMix')
    dye.data_type = 'RGBA'
    dye.blend_type = 'MULTIPLY'
    dye.inputs['Factor'].default_value = 0.18
    nt.links.new(noise.outputs['Fac'], dye.inputs['B'])
    # The weave also shows in the colour: the gaps between threads read a shade darker.
    shade = nt.nodes.new('ShaderNodeMix')
    shade.data_type = 'RGBA'
    shade.blend_type = 'MULTIPLY'
    shade.inputs['Factor'].default_value = 0.22
    ramp = nt.nodes.new('ShaderNodeMath')
    ramp.operation = 'POWER'
    ramp.inputs[1].default_value = 0.35
    nt.links.new(mix.outputs['Value'], ramp.inputs[0])
    nt.links.new(dye.outputs['Result'], shade.inputs['A'])
    nt.links.new(ramp.outputs['Value'], shade.inputs['B'])
    nt.links.new(shade.outputs['Result'], bsdf.inputs['Base Color'])
    return mat, dye


def build():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)
    scene = bpy.context.scene

    mat, dye = cloth('cloth')
    paper = bpy.data.materials.new('pages')
    paper.use_nodes = True
    paper.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = linear('#E3E6EA')
    paper.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value = 0.9

    # Back board, page block, then the front board split at the hinge.
    box('back', 0, W, 0, H, -PAGES - T, -PAGES, mat)
    box('pages', 0.004, W - 0.003, 0.003, H - 0.003, -PAGES, 0, paper, bevel=0.0003)
    box('spine', -0.006, SPINE - 0.0012, 0, H, -PAGES - T, T, mat, bevel=0.0014)
    box('front', SPINE + 0.0012, W, 0, H, 0, T, mat)
    # The hinge groove: cloth pressed down between spine and board, so no page shows through.
    box('groove', SPINE - 0.002, SPINE + 0.002, 0, H, -0.001, T - 0.0016, mat, bevel=0.0006)
    # A raised frame rule a finger's width in from the edges, as on a cloth method book.
    m = 0.016
    r = 0.0022
    x0, x1, y0, y1 = SPINE + m, W - m, m, H - m
    for name, a, b, c, d in (('rule_t', x0, x1, y1 - r, y1), ('rule_b', x0, x1, y0, y0 + r),
                             ('rule_l', x0, x0 + r, y0 + r, y1 - r), ('rule_r', x1 - r, x1, y0 + r, y1 - r)):
        box(name, a, b, c, d, T, T + 0.0009, mat, bevel=0.0003)

    def area(name, loc, rot, size, energy):
        ld = bpy.data.lights.new(name, 'AREA')
        ld.energy = energy
        ld.size = size
        lo = bpy.data.objects.new(name, ld)
        lo.location = loc
        lo.rotation_euler = rot
        scene.collection.objects.link(lo)

    # Low and from the top left, so the weave catches the light.
    area('key', (-0.25, 0.55, 0.35), (math.radians(-55), math.radians(-30), 0), 0.35, 5)
    area('fill', (0.45, -0.1, 0.4), (math.radians(20), math.radians(45), 0), 0.8, 1.2)

    world = scene.world or bpy.data.worlds.new('World')
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes['Background'].inputs['Color'].default_value = (0.03, 0.03, 0.035, 1)

    cam_data = bpy.data.cameras.new('cam')
    cam_data.type = 'ORTHO'
    cam_data.ortho_scale = H * 1.12
    cam = bpy.data.objects.new('cam', cam_data)
    # Turned a few degrees so the right-hand page edges and the board's thickness show.
    cam.rotation_euler = (0, math.radians(9), 0)
    cam.location = (W / 2 + 0.6 * math.sin(math.radians(9)), H / 2, 0.6 * math.cos(math.radians(9)))
    scene.collection.objects.link(cam)
    scene.camera = cam

    # Standard, not AgX: the covers must render in their brand colours, not a graded version.
    scene.view_settings.view_transform = 'Standard'
    r = scene.render
    r.engine = 'CYCLES'
    scene.cycles.device = 'GPU'
    scene.cycles.samples = 128
    scene.cycles.use_denoising = True
    r.film_transparent = True
    r.image_settings.file_format = 'PNG'
    r.image_settings.color_mode = 'RGBA'
    r.resolution_x = 720
    r.resolution_y = 840
    return dye


def main():
    prefs = bpy.context.preferences.addons['cycles'].preferences
    prefs.compute_device_type = 'METAL'
    prefs.get_devices()
    for d in prefs.devices:
        d.use = True
    dye = build()
    os.makedirs(OUT, exist_ok=True)
    for name, hex_colour in COVERS.items():
        dye.inputs['A'].default_value = linear(hex_colour)
        bpy.context.scene.render.filepath = os.path.abspath(os.path.join(OUT, f'cover-{name}.png'))
        bpy.ops.render.render(write_still=True)


main()
