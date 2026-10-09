"""Standalone explanatory whiteboxes; no game meshes, textures or screenshots.

Run with Blender 4.5 --background --python build_whitebox.py.
Godot ground coordinates are mapped to Blender (x, -z, height). Rooms and
placements are simplified from the two accepted case data files. Lights are
illustrations of the deduction, not a thermal simulation.
"""
import bpy
import math
import json
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

OUT = Path(__file__).resolve().parent
RENDERS = OUT / 'renders'
RENDERS.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
SC = None
MAT = {}


def material(name, color, roughness=.72, metallic=0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    bsdf = next((n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
    if bsdf is None:
        bsdf = m.node_tree.nodes.new('ShaderNodeBsdfPrincipled')
        output = next((n for n in m.node_tree.nodes if n.type == 'OUTPUT_MATERIAL'), None)
        if output is None: output = m.node_tree.nodes.new('ShaderNodeOutputMaterial')
        m.node_tree.links.new(bsdf.outputs['BSDF'], output.inputs['Surface'])
    bsdf.inputs['Base Color'].default_value = (*color, 1)
    bsdf.inputs['Roughness'].default_value = roughness
    bsdf.inputs['Metallic'].default_value = metallic
    MAT[name] = m
    return m


material('Chalk', (.77, .75, .70))
material('Paper', (.92, .90, .85))
material('Frame', (.36, .39, .38))
material('Slate', (.16, .21, .22))
material('Floor', (.64, .62, .56))
material('Glass', (.57, .68, .68))
material('Red_File', (.47, .24, .20))
material('Grey_File', (.38, .40, .39))
material('Beige_File', (.72, .62, .46))
material('Reflector', (.70, .73, .73), .28, .65)
material('Damage', (.62, .32, .24))


def finish(obj, name, mat='Chalk', bevel=.025):
    obj.name = name
    obj.data.materials.append(MAT[mat])
    if bevel:
        modifier = obj.modifiers.new('Tiny readable edges', 'BEVEL')
        modifier.width = bevel
        modifier.segments = 2
        obj.modifiers.new('Weighted normals', 'WEIGHTED_NORMAL')
    return obj


def box(name, loc, size, mat='Chalk', bevel=.025, yaw=0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.object
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.rotation_euler.z = math.radians(yaw)
    return finish(obj, name, mat, bevel)


def cylinder(name, a, b, radius=.025, mat='Frame', vertices=20):
    a, b = Vector(a), Vector(b)
    delta = b-a
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius,
                                      depth=delta.length, location=(a+b)*.5)
    obj = bpy.context.object
    obj.rotation_euler = delta.to_track_quat('Z', 'Y').to_euler()
    return finish(obj, name, mat, .009)


def local(x, z, lx, ly, h, yaw=0):
    # ly is Blender depth, independent of the source Godot z coordinate.
    angle = math.radians(yaw)
    return (x+lx*math.cos(angle)-ly*math.sin(angle),
            -z+lx*math.sin(angle)+ly*math.cos(angle), h)


def desk(x, z, restoration=False, yaw=0):
    w, d, h = (2.9, 1.55, 1.45) if restoration else (3.45, 1.55, 1.21)
    box('Restoration table' if restoration else 'Office desk', (x,-z,h), (w,d,.13), 'Paper', yaw=yaw)
    for lx in (-w/2+.2, w/2-.2):
        for ly in (-d/2+.17, d/2-.17):
            box('Table leg', local(x,z,lx,ly,h/2,yaw), (.12,.12,h-.1), yaw=yaw)
    if restoration:
        for lx in (-w/2+.2,w/2-.2):
            box('Cross rail',local(x,z,lx,0,.36,yaw),(.075,d-.24,.075),'Frame',yaw=yaw)
        box('Panel painting — whitebox', local(x,z,0,0,h+.092,yaw), (2.1,1.03,.04),'Frame',.012,yaw)
        box('Painting surface', local(x,z,0,0,h+.12,yaw),(1.97,.9,.018),'Paper',.003,yaw)
        cylinder('Scalpel raised tool',local(x,z,-.35,.08,h+.16,yaw),local(x,z,.1,.08,h+.24,yaw),.015,'Slate')
        box('Ruler',local(x,z,.20,.24,h+.17,yaw),(.78,.075,.025),'Frame',.008,yaw)
    else:
        for lx in (-w/2+.34, w/2-.34):
            box('Desk pedestal',local(x,z,lx,.0,.56,yaw),(.59,1.3,1.04),yaw=yaw)
            for i in range(3):
                box('Drawer face',local(x,z,lx,-.665,.3+i*.29,yaw),(.53,.034,.23),'Paper',.012,yaw)
                cylinder('Drawer pull',local(x,z,lx-.12,-.693,.34+i*.29,yaw),
                         local(x,z,lx+.12,-.693,.34+i*.29,yaw),.015)
        # Side wear belongs to the right outward face of the pedestal.
        for i in range(5):
            cylinder('Visible side-wear line',local(x,z,w/2-.028,-.19-i*.013,.63+i*.055,yaw),
                     local(x,z,w/2-.028,.22-i*.008,.67+i*.055,yaw),.008,'Slate')
    return h


def computer(x,z,table_h=1.21):
    box('Monitor bezel',(x,-z+.24,table_h+.62),(1.4,.105,.88),'Frame')
    box('Blank display',(x,-z+.175,table_h+.62),(1.27,.023,.74),'Glass',.012)
    box('Monitor stem',(x,-z+.24,table_h+.17),(.14,.15,.28),'Frame')
    box('Monitor foot',(x,-z+.2,table_h+.084),(.53,.35,.044),'Frame')
    box('Keyboard',(x,-z-.43,table_h+.09),(1.13,.35,.04),'Frame',.015)
    for row in range(4):
        for col in range(12):
            box('Keyboard key',(x-.50+col*.09,-z-.55+row*.075,table_h+.122),(.068,.054,.022),'Paper',.003)
    box('Work-log file',(x-.98,-z-.23,table_h+.12),(.42,.40,.10),'Chalk')


def chair(x,z,stool=False):
    base=.48 if stool else .57
    if stool:
        cylinder('Stool seat',(x,-z,.80),(x,-z,.88),.31,'Paper',32)
        for a in range(3):
            angle=a*math.tau/3
            cylinder('Stool leg',(x+math.cos(angle)*.26,-z+math.sin(angle)*.26,.06),
                     (x+math.cos(angle)*.17,-z+math.sin(angle)*.17,.8),.026)
    else:
        box('Chair seat',(x,-z,.72),(.66,.68,.11),'Chalk',.08)
        box('Chair back',(x,-z-.34,1.06),(.66,.10,.59),'Chalk',.06)
        cylinder('Chair stem',(x,-z,.12),(x,-z,.68),.063)
        for i in range(5):
            angle=i*math.tau/5
            endpoint=(x+math.cos(angle)*base,-z+math.sin(angle)*base,.12)
            cylinder('Caster spoke',(x,-z,.14),endpoint,.025)
            cylinder('Caster',(endpoint[0]-.045,endpoint[1],.085),(endpoint[0]+.045,endpoint[1],.085),.065,'Slate')


def cabinet(x,z,small=False,files=True):
    w,d,h=(1,1.4,1.12) if small else (1.39,.88,2.99)
    box('Cabinet back',(x,-z+d/2-.04,h/2),(w,.08,h))
    for sx in (-1,1):
        box('Cabinet side',(x+sx*(w/2-.04),-z,h/2),(.08,d,h))
    heights=(.09,.52,1.08) if small else (.07,.705,1.255,2.225,2.93)
    for height in heights:
        box('Shelf',(x,-z,height),(w,d,.075),'Paper')
    if not small and files:
        for i,mat in enumerate(('Red_File','Grey_File','Beige_File')):
            fx=x-.4+i*.39
            box('Middle shelf '+mat,(fx,-z-.045,1.67),(.30,.52,.74),mat,.018)
            box('File spine label',(fx,-z-.318,1.77),(.16,.015,.22),'Paper',.002)


def printer(x,z):
    box('Printer pedestal',(x,-z,.68),(.96,1.01,1.31))
    box('Printer body',(x,-z,1.46),(1.1,1.21,.28),'Paper')
    box('Scanner lid',(x,-z+.05,1.66),(1.0,.99,.08),'Frame')
    box('Paper output slot',(x,-z-.618,1.45),(.81,.03,.077),'Slate',.005)
    box('Old layout print',(x,-z-.64,1.43),(.68,.48,.01),'Paper',.001)
    for i in range(2):
        box('Printer cupboard',(x,-z-.52,.4+i*.50),(.86,.03,.4),'Paper',.012)


def dispenser(x,z):
    box('Water dispenser',(x,-z,.72),(.66,.74,1.44),'Paper')
    cylinder('Bottle shoulder',(x,-z,1.46),(x,-z,1.72),.27,'Glass',32)
    cylinder('Water bottle',(x,-z,1.72),(x,-z,2.15),.24,'Glass',32)
    box('Recessed taps',(x,-z-.38,1.0),(.46,.025,.35),'Frame')
    for sx in (-.12,.12):
        cylinder('Tap',(x+sx,-z-.4,1.06),(x+sx,-z-.48,1.06),.035,'Paper')


def tripod(x,z,kind='camera',target=None):
    headh=1.61 if kind=='camera' else (1.84 if kind=='halogen' else 1.98)
    for i in range(3):
        a=i*math.tau/3
        cylinder(kind+' tripod leg',(x+math.cos(a)*.46,-z+math.sin(a)*.46,.05),(x,-z,1.1),.026)
    cylinder(kind+' stand',(x,-z,.75),(x,-z,headh),.038)
    head=box(kind+' head',(x,-z,headh),(.48,.23,.32),'Frame',.023)
    if target:
        head.rotation_euler=(Vector(target)-head.location).to_track_quat('-Y','Z').to_euler()
    if kind=='camera':
        cylinder('Camera lens',(x,-z+.02,headh),(x,-z+.35,headh),.12,'Slate',32)
    return head


def light(name,typ,loc,power,color=(1,1,1),target=None,size=3):
    data=bpy.data.lights.new(name,typ)
    data.energy=power
    data.color=color
    if typ=='AREA': data.shape='DISK'; data.size=size
    if typ=='SPOT': data.spot_size=math.radians(69); data.spot_blend=.18; data.shadow_soft_size=.045
    obj=bpy.data.objects.new(name,data)
    SC.collection.objects.link(obj)
    obj.location=loc
    if target: obj.rotation_euler=(Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()
    return obj


def coldpanel(x,z,aim=(0,0,1.4),on=False):
    for dx in (-1.19,1.19):
        cylinder('Cold panel stand',(x+dx,-z,.1),(x+dx,-z,2.18),.026)
        box('Cold panel foot',(x+dx,-z,.08),(.38,.70,.07),'Frame')
    box('Wide cold panel frame',(x,-z,2.22),(2.78,.15,.54),'Frame')
    box('Broad diffused emitter',(x,-z-.09,2.22),(2.63,.04,.41),'Paper',.008)
    if on:
        lamp=light('Wide soft cold source','AREA',(x,-z-.12,2.23),210,(.73,.88,1),aim,2.0)
        lamp.data.shape='RECTANGLE';lamp.data.size=2.55;lamp.data.size_y=.41


def reflector(x,z,target=None):
    tripod(x,z,'reflector')
    obj=box('Metal reflector',(x,-z,1.81),(1.11,.07,.76),'Reflector')
    if target: obj.rotation_euler=(Vector(target)-obj.location).to_track_quat('-Y','Z').to_euler()


def scene(name,width=None,depth=None,wall=False,lighting='normal'):
    global SC
    SC=bpy.data.scenes.new(name)
    bpy.context.window.scene=SC
    world=bpy.data.worlds.new(name+' world')
    SC.world=world;world.use_nodes=True
    bg=next(n for n in world.node_tree.nodes if n.type=='BACKGROUND')
    bg.inputs['Color'].default_value=(.83,.86,.89,1)
    bg.inputs['Strength'].default_value=.32 if lighting=='normal' else .13
    SC.render.engine='CYCLES'
    SC.cycles.device='GPU';SC.cycles.samples=32;SC.cycles.use_denoising=True
    SC.render.resolution_x=1200;SC.render.resolution_y=720;SC.render.resolution_percentage=100
    SC.render.image_settings.file_format='PNG';SC.render.image_settings.color_mode='RGBA'
    SC.render.film_transparent=True
    SC.view_settings.view_transform='AgX'
    if width:
        box('Cutaway floor',(0,0,-.1),(width,depth,.18),'Floor',.05)
        if wall:
            box('Rear cutaway wall',(0,depth/2,.5),(width,.11,1.16))
            box('Left cutaway wall',(-width/2,0,.3),(.11,depth,.77))
        for y in range(-int(depth/2)+1,int(depth/2)):
            box('Floor grid line',(0,y,-.005),(width-.15,.007,.003),'Frame',0)
        for x in range(-int(width/2)+1,int(width/2)):
            box('Floor grid line',(x,0,-.005),(.007,depth-.15,.003),'Frame',0)
    if lighting=='normal':
        light('Large studio key','AREA',(2,-3,8),900,(1,.94,.84),(0,0,0),6)
        light('Soft fill','AREA',(-5,1,5),450,(.83,.91,1),(0,0,1),5)
    else:
        light('Dim explanatory fill','AREA',(0,-3,7),160,(.85,.9,1),(0,0,1),6)
    return SC


def camera(loc,target,ortho):
    data=bpy.data.cameras.new(SC.name+' camera')
    obj=bpy.data.objects.new(SC.name+' camera',data)
    SC.collection.objects.link(obj);obj.location=loc
    obj.rotation_euler=(Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()
    data.type='ORTHO';data.ortho_scale=ortho;data.lens=45
    SC.camera=obj


def office(full=True):
    desk(.1,-2.26);computer(.1,-2.26);chair(.15,-.62)
    if full:
        cabinet(2.3,-2.26,True)
        cabinet(-3.37,-2.55)
        printer(3.14,1.0);dispenser(-2.21,-2.49)


def restoration(actual=False,detail=False):
    x,z=(.45,-.1) if actual else (-.8,-.25)
    yaw=90 if actual else 0
    h=desk(x,z,True,yaw)
    if not detail:
        chair(.45,1.55,True) if actual else chair(-.7,1.05,True)
    if actual:
        if not detail: coldpanel(3.55,-2.48)
        target=local(x,z,-.05,0,h+.15,yaw)
        tripod(2.1,-.1,'halogen',target)
        # The emitter must sit outside its opaque whitebox housing.
        origin=Vector((2.1,.1,1.84))
        emitter=origin+(Vector(target)-origin).normalized()*.31
        light('Low warm halogen','SPOT',emitter,220,(1,.60,.26),target)
        reflector(-1.2,-.1,target)
        light('Illustrative secondary reflection','AREA',(-1.02,.1,1.80),26,(1,.77,.55),target,.30)
        if not detail: tripod(.45,2.55,'camera')
        # Small lower-right alteration serves only as a positional evidence cue.
        box('Damage correspondence',local(x,z,.75,-.32,h+.136,yaw),(.25,.14,.006),'Damage',.002,yaw)
    else:
        coldpanel(-.8,-1.9,(-.8,.25,h+.13),True)
        tripod(3.95,-2.55,'halogen')
        reflector(2.3,-2.75)
        tripod(-1.35,2.15,'camera')


plans=[]

scene('01_Studio_Hub',7.4,5.6,True)
desk(.35,-1.75);computer(.35,-1.75);chair(.3,-.04)
cabinet(-2.68,-1.9,files=False)
box('Window surround',(0,2.66,2.27),(2.7,.14,1.38),'Frame')
box('Frosted studio window',(0,2.55,2.27),(2.53,.035,1.22),'Glass')
for x in (-.82,0,.82):box('Window mullion',(x,2.52,2.27),(.045,.045,1.24),'Paper')
box('Window horizontal mullion',(0,2.52,2.26),(2.54,.045,.045),'Paper')
box('Evidence board',(2.45,2.67,2.05),(1.65,.12,1.5),'Frame')
for x,y in ((-.43,.30),(.25,.35),(-.36,-.28),(.40,-.27)):
    box('Untextured studio record',(2.45+x,2.59,2.05+y),(.42,.025,.44),'Paper',.005)
camera((11,-13,10),(0,.6,.85),8.7)
plans.append(('studio',SC,{'terminal':(.35,1.75,1.8),'chair':(.3,.04,.8)}))

scene('02_Office_Workstation',8.6,7.2,True);office(False)
camera((10,-14,11),(0,.1,.65),10.0)
plans.append(('office-workstation',SC,{'desk':(.1,2.26,1.2),'wear':(1.7,2.1,.8)}))

scene('03_Office_Restored',8.6,7.2,True);office(True)
camera((10,-14,11),(0,.35,.8),10.9)
plans.append(('office-full',SC,{'desk':(.1,2.26,1.3),'wear':(1.8,2.18,.75),
    'cabinet':(2.3,2.26,.75),'shelf':(-3.37,2.55,1.9),'printer':(3.14,-1,1.55),
    'dispenser':(-2.21,2.49,1.7),'files':(-3.37,2.2,1.75)}))

scene('04_Desk_Wear_Detail');desk(0,0);computer(0,0)
camera((5,-2.1,2.65),(1.50,0,.80),2.6)
plans.append(('office-wear',SC,{'wear':(1.696,0,.8)}))

scene('05_Middle_Shelf_Detail');cabinet(0,0)
camera((1.8,-5,2.7),(0,-.14,1.65),1.95)
plans.append(('office-files',SC,{'red':(-.4,-.33,1.7),'gray':(-.01,-.33,1.7),'beige':(.38,-.33,1.7)}))

scene('06_Conservation_Standard',10,7,True,lighting='diagnostic');restoration(False)
camera((11,-14,12),(0,.1,.85),11.3)
plans.append(('lab-standard',SC,{'table':(-.8,.25,1.45),'cold':(-.8,1.9,2.25),
    'lamp':(3.95,2.55,1.85),'reflector':(2.3,2.75,1.9),'camera':(-1.35,-2.15,1.7)}))

scene('07_Conservation_Actual',10,7,True,lighting='diagnostic');restoration(True)
camera((11,-14,12),(0,.1,.85),11.3)
plans.append(('lab-actual',SC,{'table':(.45,.1,1.45),'cold':(3.55,2.48,2.25),
    'lamp':(2.1,.1,1.85),'reflector':(-1.2,.1,1.9),'camera':(.45,-2.55,1.7)}))

scene('08_Conservation_Light_Detail',lighting='diagnostic');restoration(True,True)
camera((7,-9,9),(.45,.1,1.3),5.0)
plans.append(('lab-light',SC,{'lamp':(2.05,.1,1.83),'reflector':(-1.14,.1,1.8),
    'damage':local(.45,-.1,.75,-.32,1.59,90),'tool':local(.45,-.1,-.15,.08,1.65,90)}))

scene('09_Soft_Shadow_Detail',lighting='diagnostic')
h=desk(0,0,True);coldpanel(0,-1.65,(0,0,h+.1),True)
camera((3,-5,6),(0,0,1.4),2.65)
plans.append(('lab-soft-shadow',SC,{'tool':(-.15,.08,1.67)}))

# Use the configured NVIDIA device for actual Blender renders.
preferences=bpy.context.preferences.addons['cycles'].preferences
preferences.compute_device_type='CUDA';preferences.get_devices()
for device in preferences.devices: device.use=device.type=='CUDA'

manifest={}
for filename,sc,points in plans:
    bpy.context.window.scene=sc
    bpy.context.view_layer.update()
    if filename in ('studio','office-workstation','office-full','lab-standard','lab-actual','lab-light'):
        # Fit the complete cutaway rather than clipping tall cabinets or floors.
        coords=[world_to_camera_view(sc,sc.camera,obj.matrix_world @ Vector(v))
                for obj in sc.objects if obj.type=='MESH' for v in obj.bound_box]
        xmin,xmax=min(p.x for p in coords),max(p.x for p in coords)
        ymin,ymax=min(p.y for p in coords),max(p.y for p in coords)
        scale=sc.camera.data.ortho_scale
        right=sc.camera.matrix_world.to_quaternion() @ Vector((1,0,0))
        up=sc.camera.matrix_world.to_quaternion() @ Vector((0,1,0))
        sc.camera.location+=right*((xmin+xmax-1)*.5*scale)+up*((ymin+ymax-1)*.5*scale*.6)
        sc.camera.data.ortho_scale*=max(xmax-xmin,ymax-ymin)*1.10
        bpy.context.view_layer.update()
    manifest[filename]={'scene':sc.name,'resolution':[1200,720], 'anchors':{}}
    for name,point in points.items():
        p=world_to_camera_view(sc,sc.camera,Vector(point))
        manifest[filename]['anchors'][name]=[round(p.x*1200,2),round((1-p.y)*720,2)]

(OUT/'render-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
bpy.context.window.scene=plans[2][1]
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'scene-calibration-whiteboxes.blend'))
for filename,sc,_ in plans:
    bpy.context.window.scene=sc
    sc.render.filepath=str(RENDERS/(filename+'.png'))
    print('WHITEBOX_RENDER_START '+filename,flush=True)
    bpy.ops.render.render(write_still=True,scene=sc.name)
    print('WHITEBOX_RENDER_DONE '+filename,flush=True)
print('WHITEBOX_KIT_COMPLETE',flush=True)
