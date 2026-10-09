"""Reconstruct three production stages for three environments in Blender.

These are retrospective explanatory studies, not recovered historical files.
Stage 1 uses exactly one unmodified 8-vertex box per object. No constituent
monitor, keyboard, table legs or chair parts are built at that stage.
Stage 2 establishes recognizable forms. Stage 3 adds meshes and set dressing.
Final lighting images are separately captured from Godot, not Blender.
"""
from pathlib import Path
import json
import math

HERE=Path(__file__).resolve().parent
utility=(HERE.parent/'whitebox'/'build_whitebox.py').read_text(encoding='utf-8').split('plans=[]')[0]
exec(compile(utility,str(HERE.parent/'whitebox'/'build_whitebox.py'),'exec'))
OUT=HERE
RENDERS=HERE/'renders'
RENDERS.mkdir(parents=True,exist_ok=True)
DATA=json.loads((HERE/'final'/'scene-manifest.json').read_text(encoding='utf-8'))
STAGE=1
AUDIT={}

# A neutral clay vocabulary; no final-game surface textures are imported.
for name in ('Red_File','Grey_File','Beige_File','Damage'):
    MAT[name]=MAT['Chalk']


def g(v):return (v[0],-v[2],v[1])


def cube_object(name,x,z,w,d,h,base=0,yaw=0):
    obj=box(name,(x,-z,base+h/2),(w,d,h),'Chalk',0,yaw)
    obj['stage_1_single_block']=True
    return obj


def room(id):
    width,depth,zcenter=(10,8.4,-.7) if id=='studio' else ((8.6,7.2,0) if id=='office' else (10,7,0))
    box('Room floor',(0,-zcenter,-.13),(width,depth,.24),'Floor',0 if STAGE==1 else .015)
    back=zcenter-depth/2
    # Each entire wall is one block at the occupancy stage.
    box('Rear wall',(0,-back,1.65),(width,.13,3.3),'Chalk',0 if STAGE==1 else .015)
    side=1 if id=='office' else -1
    x=side*width/2
    winz=-1 if id=='office' else -.9
    window_d=4.0 if id=='office' else 3.0
    if STAGE==1:
        box('Side wall',(x,-zcenter,1.65),(.13,depth,3.3),'Chalk',0)
        box('Window placeholder',(x-side*.08,-winz,2.04),(.055,window_d,1.8),'Paper',0)
    else:
        box('Side wall lower',(x,-zcenter,.60),(.13,depth,1.2))
        box('Side wall upper',(x,-zcenter,3.12),(.13,depth,.36))
        for lo,hi in ((back,winz-window_d/2),(winz+window_d/2,zcenter+depth/2)):
            if hi>lo:box('Window pier',(x,-(lo+hi)/2,2.08),(.13,hi-lo,1.76))
        box('Window pane',(x-side*.028,-winz,2.08),(.055,window_d,1.69),'Glass',.003)
        for zz in (-window_d/2,0,window_d/2):
            box('Window mullion',(x-side*.09,-winz+zz,2.08),(.08,.045,1.8),'Frame',.006)
        for hh in (1.18,2.08,2.98):
            box('Window crossbar',(x-side*.09,-winz,hh),(.08,window_d+.09,.045),'Frame',.006)
        box('Window sill',(x-side*.17,-winz,1.12),(.40,window_d+.30,.10),'Paper')
    if STAGE==3:
        for h in (.16,3.23):box('Rear wall trim',(0,-back-.09,h),(width,.04,.065),'Frame',.005)
        for xx in range(-4,5,2):box('Rear panel seam',(xx,-back-.074,1.66),(.012,.009,3.08),'Frame',.002)
        if id!='restoration':
            for i in range(10):
                box('Venetian slat',(x-side*.1,-winz,2.94-i*.08),(.09,window_d,.016),'Frame',.004)
        if id=='studio':
            for i in range(13):
                zz=winz-1.14+i*.19
                cylinder('Radiator fin',(x-side*.20,-zz,.15),(x-side*.20,-zz,.75),.049)
        # Seams are geometry, not textured material snapshots from the game.
        for i in range(int(depth/.4)):
            yy=-zcenter-depth/2+i*.4
            box('Floor seam',(0,yy,.001),(width-.04,.009,.006),'Frame',0)
            if id=='restoration':
                for xx in range(-4,5):box('Tile seam',(xx,-zcenter,.002),(.007,depth,.003),'Frame',0)
            else:
                for xx in range(-4,5,2):
                    box('Plank joint',(xx+(.65 if i%2 else 0),yy+.2,.002),(.008,.39,.004),'Frame',0)


def desk_model(x,z,w=3.45,d=1.55,h=1.21,drawers=True):
    box('Worktop',(x,-z,h),(w,d,.12),'Paper')
    if drawers:
        for sx in (-1,1):
            px=x+sx*(w/2-.34)
            box('Desk pedestal',(px,-z,h*.47),(.59,d-.21,h-.17))
            for i in range(3):
                y=.25+i*.29
                box('Drawer front',(px,-z-d/2+.087,y),(.52,.03,.24),'Paper',.01)
                if STAGE==3:cylinder('Drawer handle',(px-.12,-z-d/2+.063,y),(px+.12,-z-d/2+.063,y),.012)
    else:
        for sx in (-1,1):
            for sy in (-1,1):
                box('Table leg',(x+sx*(w/2-.17),-z+sy*(d/2-.14),h/2),(.075,.075,h))
            if STAGE==3:box('Table cross rail',(x+sx*(w/2-.17),-z,.32),(.05,d-.2,.05),'Frame')


def computer_model(x,z,h=1.21):
    box('Monitor housing',(x,-z+.16,h+.57),(1.3,.14,.80),'Frame')
    box('Blank screen',(x,-z+.077,h+.57),(1.15,.025,.66),'Glass',.008)
    box('Screen stand',(x,-z+.15,h+.13),(.13,.12,.22))
    box('Screen base',(x,-z+.13,h+.035),(.47,.32,.05))
    box('Keyboard',(x,-z-.45,h+.075),(1.13,.36,.06),'Frame',.015)
    if STAGE==3:
        for row in range(4):
            for col in range(12):box('Keyboard key',(x-.5+col*.09,-z-.56+row*.077,h+.113),(.070,.053,.022),'Paper',.003)
        for i in range(6):box('Display vent',(x+.42,-z+.241,h+.32+i*.060),(.19,.015,.013),'Slate',0)
        mouse=box('Mouse',(x+.84,-z-.42,h+.083),(.16,.26,.10),'Frame',.062)


def seat(x,z,stool=False):
    if stool:
        cylinder('Stool seat',(x,-z,.75),(x,-z,.85),.29,'Chalk',28)
        cylinder('Stool column',(x,-z,.23),(x,-z,.75),.055)
        for i in range(4):
            angle=i*math.tau/4
            cylinder('Stool foot',(x,-z,.25),(x+math.cos(angle)*.30,-z+math.sin(angle)*.30,.08),.025)
        if STAGE==3:
            bpy.ops.mesh.primitive_torus_add(major_radius=.19,minor_radius=.016,location=(x,-z,.35))
            finish(bpy.context.object,'Stool foot ring','Frame',0)
    else:
        box('Office chair seat',(x,-z,.66),(.65,.63,.10),'Chalk',.045)
        box('Office chair back',(x,-z-.31,1.04),(.62,.10,.62),'Chalk',.06)
        cylinder('Chair stem',(x,-z,.12),(x,-z,.65),.06)
        for i in range(5):
            a=i*math.tau/5
            point=(x+math.cos(a)*.43,-z+math.sin(a)*.43,.12)
            cylinder('Chair foot',(x,-z,.14),point,.025)
            if STAGE==3:cylinder('Caster',(point[0]-.039,point[1],.078),(point[0]+.039,point[1],.078),.058,'Slate')
        if STAGE==3:
            for sx in (-1,1):
                cylinder('Arm support',(x+sx*.4,-z,.65),(x+sx*.4,-z,.90),.024)
                box('Padded chair arm',(x+sx*.4,-z,.93),(.10,.44,.055),'Frame',.026)


def shelving(x,z,w=1.39,d=.88,h=2.99,books=False):
    box('Shelf back',(x,-z+d/2-.035,h/2),(w,.07,h))
    for sx in (-1,1):box('Shelf side',(x+sx*(w/2-.035),-z,h/2),(.07,d,h))
    levels=5 if books else 4
    for i in range(levels):box('Shelf',(x,-z,.07+i*(h-.14)/(levels-1)),(w,d,.065),'Paper')
    if STAGE==3:
        if books:
            for level in range(levels-1):
                for j in range(10):
                    xx=x-w/2+.16+j*(w-.32)/10
                    hh=.40+.07*(j%3)
                    box('Archive book',(xx,-z-.02,.13+level*(h-.14)/(levels-1)+hh/2),(.10,d*.58,hh),'Chalk',.008)
                    box('Book spine label',(xx,-z-d*.31,.36+level*(h-.14)/(levels-1)),(.07,.011,.06),'Paper',.001)
        else:
            for i in range(3):
                xx=x-.41+i*.39
                box('Middle shelf file',(xx,-z-.05,1.64),(.30,.54,.74),'Chalk',.01)
                box('File label',(xx,-z-.326,1.72),(.17,.012,.2),'Paper',.001)


def drawer_cabinet(x,z,w,d,h,n=3,yaw=0):
    box('Cabinet body',(x,-z,h/2),(w,d,h),'Chalk',yaw=yaw)
    box('Cabinet top',(x,-z,h+.028),(w+.06,d+.055,.055),'Paper',yaw=yaw)
    for i in range(n):
        y=.12+(h-.13)/n*(i+.5)
        box('Cabinet drawer',local(x,z,0,-d/2-.017,y,yaw),(w-.07,.025,(h-.16)/n-.018),'Paper',.009,yaw)
        if STAGE==3:
            for dx in (-w*.26,w*.26):
                cylinder('Pull',local(x,z,dx-.07,-d/2-.035,y,yaw),local(x,z,dx+.07,-d/2-.035,y,yaw),.01)


def printer_model(x,z,h=1.3):
    box('Printer housing',(x,-z,h+.15),(1.05,1.1,.29),'Paper')
    box('Scanner lid',(x,-z,h+.325),(.96,1,.065),'Frame')
    if STAGE==3:
        box('Paper slot',(x,-z-.56,h+.13),(.75,.02,.05),'Slate',.004)
        box('Printed page',(x,-z-.70,h+.11),(.61,.44,.012),'Paper',.002)
        box('Control panel',(x+.33,-z-.42,h+.32),(.18,.20,.025),'Glass',.004)


def props(x,z,h):
    # Readable object-scale dressing, built afresh rather than importing game meshes.
    for i in range(4):
        p=box('Loose document',(x-.77+i*.11,-z-.22+(i%2)*.12,h+.012+i*.009),(.43,.55,.009),'Paper',.002,yaw=i*8-9)
    cylinder('Mug',(x+.89,-z-.23,h+.01),(x+.89,-z-.23,h+.24),.10,'Paper',32)
    cylinder('Desk lamp foot',(x-1.12,-z+.28,h+.01),(x-1.12,-z+.28,h+.05),.17,'Frame',32)
    cylinder('Desk lamp stem',(x-1.12,-z+.28,h+.04),(x-1.12,-z+.28,h+.63),.026)
    bpy.ops.mesh.primitive_cone_add(vertices=32,radius1=.28,radius2=.095,depth=.24,location=(x-1.12,-z+.28,h+.67))
    finish(bpy.context.object,'Desk lamp shade','Chalk',.012)
    box('Closed journal',(x-.73,-z-.31,h+.10),(.43,.47,.13),'Chalk',.012)


def plant_model(x,z,base=0):
    bpy.ops.mesh.primitive_cone_add(vertices=24,radius1=.21,radius2=.29,depth=.43,location=(x,-z,base+.215))
    finish(bpy.context.object,'Plant pot','Chalk',.012)
    if STAGE==2:
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=8,location=(x,-z,base+.85),scale=(.39,.36,.46))
        finish(bpy.context.object,'Foliage mass','Chalk',0)
    else:
        for i in range(10):
            a=i*2.399
            end=(x+math.cos(a)*.33,-z+math.sin(a)*.33,base+.75+.37*(i%3)/2)
            cylinder('Leaf petiole',(x,-z,base+.43),end,.012)
            direction=Vector((math.cos(a)*.45,math.sin(a)*.45,.12))
            side=Vector((-math.sin(a)*.08,math.cos(a)*.08,0))
            origin=Vector(end)-direction*.23
            verts=[origin,origin+direction*.45+side,origin+direction,origin+direction*.45-side,origin+direction*.45+Vector((0,0,.025))]
            mesh=bpy.data.meshes.new('Leaf topology');mesh.from_pydata(verts,[],[(0,1,4),(1,2,4),(2,3,4),(3,0,4)])
            obj=bpy.data.objects.new('Pointed curved leaf',mesh);SC.collection.objects.link(obj);obj.data.materials.append(MAT['Chalk'])
            solid=obj.modifiers.new('Leaf thickness','SOLIDIFY');solid.thickness=.008


def board(x,z,h,w=2.7,d=1.15):
    box('Board frame',(x,-z,h),(w,.10,d),'Frame')
    box('Blank board',(x,-z-.06,h),(w-.10,.025,d-.10),'Chalk')
    if STAGE==3:
        if w<1:
            box('Photo mount',(x,-z-.084,h),(w-.15,.013,d-.15),'Paper',.002)
            return
        for i in range(8):
            px=x-w*.36+(i%4)*w*.235
            zz=h-.34+(i//4)*.65
            box('Evidence card',(px,-z-.08,zz),(.36,.013,.42),'Paper',.003,yaw=0)
        for i in range(5):
            cylinder('Connecting thread',(x-.85,-z-.10,h-.30+i*.13),(x+.72,-z-.10,h+.36-i*.10),.006)


def studio():
    if STAGE==1:
        objects=[('Desk',-2,-1.65,3.45,1.55,1.21,0),('Computer',-2,-1.65,1.75,1.15,1.16,1.21),
          ('Chair',-2,.05,1.13,1.13,1.35,0),('Bookcase',3.4,-4.42,2.4,.7,2.9,0),
          ('Printer cabinet',1.85,-4.32,.94,.8,1.92,0),('Workbench',.4,-3.82,1.9,.94,1.65,0),
          ('Window bookcase',-4.43,1.43,.68,1.52,.89,0),('Sofa',3.05,.45,2.8,1.1,1.25,0),
          ('Coffee table',2.85,2.03,1.92,.9,.80,0),('Floor lamp',4.5,.78,.7,.7,2,0),
          ('Plant stand',4.3,2,.6,.6,.48,0),('Plant A',-4.35,1.5,1.09,.96,1.28,.91),('Plant B',4.3,2,1.09,.96,1.28,.5)]
        for name,x,z,w,d,h,b in objects:cube_object(name,x,z,w,d,h,b)
        cube_object('Evidence board',-2.73,-4.72,3.7,.17,2.09,1.02)
        cube_object('Rug',2.9,1.55,3.7,2.85,.025,.022)
        return
    desk_model(-2,-1.65);computer_model(-2,-1.65);seat(-2,.05)
    shelving(3.4,-4.42,2.4,.7,2.9,True)
    drawer_cabinet(1.85,-4.32,.86,.7,1.4,4);printer_model(1.85,-4.32,1.45)
    shelving(-4.43,1.43,.68,1.52,.89,True)
    desk_model(.4,-3.82,1.9,.94,1.08,False);seat(.4,-2.97,True)
    board(-2.73,-4.72,2.07,3.7,2.09)
    box('Sofa base',(3.05,-.45,.44),(2.8,1.1,.53),'Chalk',.065)
    box('Sofa back',(3.05,-.9,.98),(2.8,.20,.67),'Chalk',.07)
    for sx in (-1,1):box('Sofa arm',(3.05+sx*1.32,-.45,.78),(.21,1.06,.61),'Chalk',.06)
    desk_model(2.85,2.03,1.92,.9,.54,False)
    box('Rug',(2.9,-1.55,.025),(3.7,2.85,.025),'Floor',.008)
    cylinder('Floor lamp stand',(4.5,-.78,.10),(4.5,-.78,1.64),.028)
    cylinder('Floor lamp base',(4.5,-.78,.04),(4.5,-.78,.11),.27,'Frame',32)
    bpy.ops.mesh.primitive_cone_add(vertices=32,radius1=.34,radius2=.24,depth=.5,location=(4.5,-.78,1.75))
    finish(bpy.context.object,'Floor lamp shade','Paper',.008)
    box('Plant stand',(4.3,-2,.25),(.6,.6,.48))
    plant_model(-4.35,1.5,.91);plant_model(4.3,2,.50)
    if STAGE==3:
        props(-2,-1.65,1.21)
        box('Coffee table book',(2.90,-2.04,.63),(.40,.48,.12),'Paper',.015)
        cylinder('Coffee mug',(2.35,-1.88,.59),(2.35,-1.88,.78),.087,'Chalk',24)
        for i in range(3):box('Sofa seat cushion',(2.16+i*.89,-.45,.76),(.85,.79,.15),'Paper',.065)
        for i in range(2):box('Loose sofa cushion',(2.43+i*1.10,-.68,.99),(.44,.15,.39),'Paper',.06)
        box('Workbench cutting mat',(.4,3.82,1.15),(1.45,.73,.025),'Frame',.004)
        box('Miniature floor',(.4,3.82,1.185),(.93,.62,.035),'Paper')
        box('Miniature back wall',(.4,4.12,1.34),(.93,.035,.31),'Chalk')
        box('Miniature side wall',(-.05,3.82,1.34),(.035,.62,.31),'Chalk')
        for i in range(3):box('Miniature furniture',(.16+i*.24,3.99,1.31),(.18,.13,.16),'Paper',.005)
        for i in range(3):board(-.15+i*.66,-4.76,2.48,.54,.55)


def office_scene():
    if STAGE==1:
        for name,x,z,w,d,h,b in [
            ('Desk',.1,-2.26,3.45,1.55,1.21,0),('Computer',.1,-2.26,1.75,1.15,1.16,1.21),
            ('Chair',.15,-.62,1.13,1.13,1.35,0),('Small cabinet',2.3,-2.26,1,1.6,1.16,0),
            ('Tall cabinet',-3.37,-2.55,1.42,.88,2.99,0),('Dispenser',-2.21,-2.49,.65,.85,2.32,0),
            ('Printer',3.14,1,1.36,1.74,1.76,0),('Wastebasket',-1.85,-1.47,.6,.6,.64,0),
            ('Plant',3.55,2.25,.97,.92,1.29,.06)]:cube_object(name,x,z,w,d,h,b)
        cube_object('Noticeboard',.2,-3.4,2.7,.13,1.15,1.77)
        return
    desk_model(.1,-2.26);computer_model(.1,-2.26);seat(.15,-.62)
    drawer_cabinet(2.3,-2.26,1,1.56,1.12,3)
    shelving(-3.37,-2.55)
    drawer_cabinet(3.14,1,1.1,1.36,1.32,2);printer_model(3.14,1,1.34)
    dispenser(-2.21,-2.49)
    board(.2,-3.4,2.34)
    cylinder('Wastebasket',(-1.85,1.47,.03),(-1.85,1.47,.65),.28,'Chalk',24)
    plant_model(3.55,2.25,.06)
    if STAGE==3:
        props(.1,-2.26,1.21)
        for i in range(6):cylinder('Desk contact scratch',(1.79,2.19-i*.023,.64+i*.04),(1.79,2.55-i*.024,.67+i*.04),.006,'Frame')
        for i in range(7):
            angle=i*.40
            cylinder('Chair wheel-floor trace',(.15+math.cos(angle)*.61,.62+math.sin(angle)*.49,.018),(.15+math.cos(angle+.24)*.61,.62+math.sin(angle+.24)*.49,.018),.005)


def conservation():
    if STAGE==1:
        for name,x,z,w,d,h,b in [
            ('Restoration table',-.8,-.25,2.9,1.55,1.78,0),('Stool',-.7,1.05,.63,.72,.83,0),
            ('Cold light panel',-.8,-1.9,2.92,1.09,2.5,0),('Camera',-1.35,2.15,.9,1.02,1.68,0),
            ('Reflector',2.3,-2.75,1.36,.7,2.27,0),('Halogen lamp',3.95,-2.55,.69,1.12,1.89,0),
            ('Flat-file cabinet',-4.42,-.7,.81,2.43,1.28,0),('Materials cabinet',-3.25,-2.95,1.18,.81,1.81,0),
            ('Frame rack',-4.5,2,.65,1.36,1.78,0),('Trolley',3.85,1.8,1.05,.65,1.58,0)]:cube_object(name,x,z,w,d,h,b)
        return
    desk_model(-.8,-.25,2.9,1.55,1.16,False);seat(-.7,1.05,True)
    box('Painting board',(-1,.30,1.28),(1.78,1.03,.08),'Paper')
    coldpanel(-.8,-1.9,on=False)
    tripod(-1.35,2.15,'camera');reflector(2.3,-2.75);tripod(3.95,-2.55,'halogen')
    drawer_cabinet(-4.42,-.7,2.35,.7,.95,6,90)
    drawer_cabinet(-3.25,-2.95,1.1,.7,1.23,3)
    box('Frame rack base',(-4.5,-2,.06),(.65,1.35,.10),'Frame')
    for y in (1.90,2.30):
        for zz in (.18,1.76):box('Stored frame rail',(-4.5,-y,zz),(.06,.66,.07),'Chalk')
        for dy in (-.30,.30):box('Stored frame stile',(-4.5,-y+dy,.97),(.06,.07,1.6),'Chalk')
    for height in (.20,.59,1):box('Supply trolley tray',(3.85,-1.8,height),(1.05,.60,.05),'Chalk')
    for xx in (3.36,4.34):
        for yy in (-1.55,-2.05):cylinder('Trolley post',(xx,yy,.1),(xx,yy,1.1),.026)
    if STAGE==3:
        for zz in (-.19,.81):box('Painting frame rail',(-1,zz,1.35),(1.78,.06,.06),'Frame')
        for xx in (-1.86,-.14):box('Painting frame stile',(xx,.31,1.35),(.06,1.03,.06),'Frame')
        for i in range(5):
            xx=-1.65+i*.32
            cylinder('Conservation bottle',(xx,.80,1.25),(xx,.80,1.46+.04*(i%2)),.045,'Chalk',16)
            cylinder('Bottle cap',(xx,.80,1.46+.04*(i%2)),(xx,.80,1.49+.04*(i%2)),.035,'Frame',16)
            cylinder('Trolley supply bottle',(3.47+i*.17,-1.8,1.03),(3.47+i*.17,-1.8,1.28),.047,'Chalk',16)
        cylinder('Raised scalpel',(-1.32,.28,1.38),(-.90,.28,1.43),.014)
        box('Measurement ruler',(-.55,.14,1.36),(.65,.075,.016),'Frame',.004)
        for xx in (3.36,4.34):
            for yy in (-1.55,-2.05):cylinder('Trolley caster',(xx-.035,yy,.075),(xx+.035,yy,.075),.065,'Frame',20)
        for i in range(4):box('Folded cloth',(3.85,-1.8,.63+i*.022),(.47,.38,.019),'Paper',.004)
        for xx in (-2.7,-.7,1.3):box('Calibration rail bracket',(xx,3.3,2.95),(.13,.15,.12),'Frame')
        box('Wall calibration rail',(-.7,3.30,2.98),(4.7,.1,.07),'Frame')
        for xx in (1.1,1.75):box('Calibration notice',(xx,3.40,1.9),(.47,.015,.70),'Paper')


def use_game_camera(id):
    entry=DATA[id]
    camera(g(entry['camera_position']),Vector(g(entry['camera_position']))+Vector(g(entry['camera_forward'])),entry['ortho_width'])
    SC.render.resolution_x=1200;SC.render.resolution_y=750
    SC.render.film_transparent=False
    SC.cycles.samples=40


plans=[]
for id in ('studio','office','restoration'):
    for level in (1,2,3):
        STAGE=level
        scene(f'{id.upper()} / {level:02d} / '+('Occupancy blocks','Form and structure','Detailed clay')[level-1])
        room(id)
        {'studio':studio,'office':office_scene,'restoration':conservation}[id]()
        use_game_camera(id)
        SC['stage']=level;SC['space']=id;SC['historical_status']='Reconstructed process study'
        if level==1:
            objects=[obj for obj in SC.objects if obj.get('stage_1_single_block')]
            assert(all(len(obj.data.vertices)==8 and not obj.modifiers for obj in objects))
            AUDIT[id]={'object_blocks':len(objects),'all_objects_single_8_vertex_boxes':True,'modelled_keyboard_parts':0}
        plans.append((f'{id}-stage-{level}',SC))

preferences=bpy.context.preferences.addons['cycles'].preferences
preferences.compute_device_type='CUDA';preferences.get_devices()
for device in preferences.devices:device.use=device.type=='CUDA'
for sc in list(bpy.data.scenes):
    if not sc.objects:bpy.data.scenes.remove(sc)
bpy.context.window.scene=plans[2][1]
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.region_3d.view_perspective='CAMERA'
            area.spaces.active.shading.color_type='MATERIAL'
bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'three-scenes-production-studies.blend'))
(HERE/'stage-1-audit.json').write_text(json.dumps(AUDIT,indent=2),encoding='utf-8')
for filename,sc in plans:
    bpy.context.window.scene=sc
    sc.render.filepath=str(RENDERS/(filename+'.png'))
    print('PROCESS_RENDER_START '+filename,flush=True)
    bpy.ops.render.render(write_still=True,scene=sc.name)
    print('PROCESS_RENDER_DONE '+filename,flush=True)
print('PROCESS_WHITEBOX_COMPLETE',flush=True)
