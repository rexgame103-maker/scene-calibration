"""Page 03: native, editable newspaper SVG with genuine Blender whiteboxes."""
from pathlib import Path
from html import escape
import json
from build_pages import OUT, INK, MUTED, RUST, uri, text, paragraph, rule, vertical, paper, measure

STEM = '03-mechanics-level-loop'
KIT = OUT / 'whitebox'
RENDERS = KIT / 'renders'
ANCHORS = json.loads((KIT / 'render-manifest.json').read_text(encoding='utf-8'))
BLUE = '#496b71'
GREEN = '#50674f'
CREAM = '#f9f2e4'


def body(x,y,width,copy,size=17,leading=23,kind='serif',fill=INK):
    return paragraph(x,y,width,copy,size,leading,kind,fill)[0]


def path(d,color=RUST,width=1.8,arrow=False,dash=None):
    return (f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{width}" '
            f'stroke-linecap="round" stroke-linejoin="round"'
            +(f' marker-end="url(#arrow-{color[1:]})"' if arrow else '')
            +(f' stroke-dasharray="{dash}"' if dash else '')+'/>' )


def render(name,x,y,w,rotation=0):
    h=w*.6
    u=uri(RENDERS/(name+'.png'))
    return (f'<g id="whitebox-{name}-{x}" aria-label="Blender whitebox: {escape(name)}" '
            f'transform="rotate({rotation} {x+w/2} {y+h/2})">'
            f'<image x="{x}" y="{y}" width="{w}" height="{h}" href="{u}" xlink:href="{u}"/></g>')


def anchor(name,point,x,y,w):
    px,py=ANCHORS[name]['anchors'][point]
    return x+px*w/1200,y+py*w/1200


def dot(x,y,n,color=RUST,size=11):
    return (f'<circle cx="{x}" cy="{y}" r="{size}" fill="{color}" stroke="{CREAM}" stroke-width="1.5"/>'
            +text(x,y+4,str(n),13,'sansbold',CREAM,'middle'))


def tag(x,y,copy,color=RUST,size=13):
    width=measure(copy,size,'sansbold')+12
    return (f'<rect x="{x-5}" y="{y-size-3}" width="{width}" height="{size+9}" fill="{CREAM}" opacity=".94"/>'
            +text(x,y,copy,size,'sansbold',color))


def step(x,y,n,title,copy,width=371):
    return dot(x-20,y-6,n)+text(x,y,title,19,'sansbold')+body(x,y+25,width,copy,17,23)


def build():
    s=paper('Scene Calibration — Mechanics & the Case Loop',
            'English 16:9 design dossier. Three spaces only: the player studio, the office case and the conservation lab case. All scene images are original Blender explanatory whiteboxes, not game screenshots. Text, diagrams and annotations are editable SVG.')
    defs=''
    for color in (RUST,BLUE,GREEN):
        defs+=f'<marker id="arrow-{color[1:]}" viewBox="0 0 10 10" refX="8.5" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path d="M1 1L9 5 1 9" fill="none" stroke="{color}" stroke-width="1.3"/></marker>'
    s=s.replace('</defs>',defs+'</defs>')
    s+='<g id="masthead">'
    s+=text(50,46,'SCENE CALIBRATION / DESIGN DOSSIER',15,'sansbold')
    s+=text(1870,46,'NO. 03 / MECHANICS & LEVEL DESIGN',15,'sans',anchor='end')
    s+=rule(50,59,1820,weight=1.2)
    s+=text(50,128,'MECHANICS & THE CASE LOOP',66,'bold')
    s+=text(51,163,'Read the evidence. Rebuild the relationships. Test the story against the room.',23,'italic',MUTED)
    s+=rule(50,179,1820,RUST,4)
    s+='</g>'

    # Five connected actions, with a visible return route to the studio.
    s+='<g id="shared-game-loop">'
    xs=[50,416,782,1148,1514]
    labels=['01 / ACCEPT','02 / OBSERVE','03 / RECONSTRUCT','04 / VERIFY','05 / RETURN']
    for x,label in zip(xs,labels):s+=text(x,213,label,21,'bold')
    for x in (369,735,1101,1467):s+=path(f'M{x} 207h26',arrow=True)
    s+=render('studio',64,230,283)
    s+=render('office-wear',436,241,258)
    s+=render('office-workstation',790,229,283)
    s+=render('lab-light',1168,230,275)
    # Editable archive cards show the reward loop without inventing a fourth room.
    s+='<g id="photo-archive" transform="rotate(-4 1667 316)">'
    s+=f'<rect x="1552" y="260" width="253" height="126" fill="{CREAM}" stroke="{MUTED}" stroke-width="1"/>'
    s+=f'<rect x="1565" y="248" width="253" height="126" fill="{CREAM}" stroke="{INK}" stroke-width="1"/>'
    s+=rule(1580,277,223,RUST,2)
    s+=text(1580,269,'RESTORED SCENE / ARCHIVE',14,'sansbold')
    s+=text(1580,314,'PHOTO + CASE FEE',20,'bold')
    s+=text(1580,345,'EQUIP THE STUDIO',17,'sansbold',GREEN)
    s+='</g>'
    core=[
        'Open studio mail and accept a case. Photos and records provide the first incomplete view.',
        'Read documents; orbit the room. A trace is clickable only when its surface is visible and unobstructed.',
        'Unlock objects, drag them into place, rotate and undo. Infer support, adjacency, order and orientation.',
        'Test the arrangement against the evidence. A plausible-looking room still needs every required match.',
        'Photograph the solved scene, earn a fee and return. Buy and place studio equipment; then read the next mail.'
    ]
    for x,copy in zip(xs,core):s+=body(x,415,329,copy,16,20,'sans')
    s+=path('M1848 461v19H68v-14',BLUE,1.5,True,'5 5')
    s+=tag(744,485,'ARCHIVE → REINVEST → NEXT ASSIGNMENT',BLUE,12)
    s+='</g>'

    s+=rule(50,502,1820,weight=1.3)
    s+=vertical(953,518,509,.5)

    # Office: the spatial puzzle advances through dependencies, not free placement.
    s+='<g id="case-01-office">'
    s+=text(50,526,'CASE 01 / OFFICE',15,'sansbold',RUST)
    s+=text(50,561,'The Missing Blue File',32,'bold')
    s+=text(922,526,'SPACE + EVIDENCE',14,'sansbold',MUTED,'end')
    s+=render('office-full',38,578,464)
    # Actual projected locations connect the model to the five logical gates.
    for point,n in (('desk',1),('cabinet',2),('shelf',3),('printer',4)):
        ax,ay=anchor('office-full',point,38,578,464)
        s+=dot(ax,ay,n)
    ax,ay=anchor('office-full','files',38,578,464)
    s+=path(f'M{ax:.1f} {ay:.1f}L294 865',BLUE,1.4,True)
    ax,ay=anchor('office-full','wear',38,578,464)
    s+=path(f'M{ax:.1f} {ay:.1f}L143 865',RUST,1.4,True,'4 3')
    s+=tag(52,840,'A POSITION IS A CLAIM ABOUT THE PAST',BLUE,12)
    s+=text(54,869,'VISIBLE SIDE WEAR',14,'sansbold',RUST)
    s+=render('office-wear',55,880,220)
    s+=text(299,869,'MIDDLE SHELF ORDER',14,'sansbold',BLUE)
    s+=render('office-files',308,879,195)
    s+=text(54,1021,'Orbit → inspect → unlock',16,'italic',MUTED)
    s+=text(305,1017,'RED → GRAY → BEIGE',14,'sansbold',RUST)

    x=550
    s+=path(f'M{x-20} 593V975',RUST,1.4,dash='3 5')
    s+=step(x,594,1,'CROPPED PHOTO → WORKSTATION',
        'The email image confirms a desk, chair and computer. Restoring all three unlocks the next investigation.',371)
    s+=step(x,682,2,'SIDE WEAR → SMALL CABINET',
        'Inspect the desk’s right face from a clear angle. Contact marks identify the cabinet that stood beside it.',371)
    s+=step(x,770,3,'TERMINAL LOG → EQUIPMENT',
        'After the cabinet fits, a work log reveals the tall file cabinet and printer. Restore both to the equipment wall.',371)
    s+=step(x,858,4,'PRINTED PHOTO → FINAL OBJECTS',
        'The printer reveals an old layout: dispenser beside the tall cabinet; red, gray and beige files on its middle shelf.',371)
    s+=step(x,946,5,'ALL 10 RELATIONSHIPS → COMPLETE',
        'Correct objects, locations and required clues must agree. Archive the restoration and return to the studio: ¥1,200.',371)
    s+='</g>'

    # Restoration: compare the reported standard with the scene that explains damage.
    s+='<g id="case-02-conservation-lab">'
    s+=text(982,526,'CASE 02 / CONSERVATION LAB',15,'sansbold',RUST)
    s+=text(982,561,'The Miscalibrated Restoration Room',29,'bold')
    s+=text(1870,526,'SPACE + LIGHT + RECORDS',14,'sansbold',MUTED,'end')
    s+=render('lab-standard',976,591,322)
    s+=render('lab-actual',1300,591,322)
    s+=text(989,591,'A / REPORTED STANDARD',14,'sansbold',BLUE)
    s+=text(1313,591,'B / RECONSTRUCTED ACTUAL',14,'sansbold',RUST)
    s+=path('M1281 683q22 -35 42 -3',RUST,2,True)
    s+=tag(1288,733,'90°',RUST,17)
    for name,key,x,color,n in [('lab-standard','cold',976,BLUE,'C'),('lab-actual','lamp',1300,RUST,'H'),('lab-actual','reflector',1300,BLUE,'R')]:
        ax,ay=anchor(name,key,x,591,322);s+=dot(ax,ay,n,color,10)
    s+=body(989,798,303,'Cold panel at the table. Halogen lamp and reflector parked. Camera records a standard baseline.',16,21)
    s+=body(1313,798,303,'Table turns 90°. Cold panel is weakened; halogen moves right, reflector left, camera realigned.',16,21)

    s+=text(1645,598,'THREE PHOTO SIGNATURES',16,'sansbold',RUST)
    clues=[('SHARP SHADOW','Hard, elongated shadows imply a low point source on the right.'),
           ('WARM + SECOND HIGHLIGHT','Warm light and a second highlight imply a reflected path.'),
           ('ROTATED FRAME','Ruler and artwork projections imply a 90° table rotation.')]
    for y,(title,copy) in zip((631,705,779),clues):
        s+=text(1645,y,title,14,'sansbold',BLUE)
        s+=body(1645,y+23,225,copy,16,21,'sans')

    s+=rule(982,861,888,weight=.8,opacity=.6)
    # Low lamp and reflector path is an explanatory overlay, not thermal simulation.
    s+=render('lab-light',974,877,289)
    a=anchor('lab-light','lamp',974,877,289)
    b=anchor('lab-light','reflector',974,877,289)
    d=anchor('lab-light','damage',974,877,289)
    s+=path(f'M{a[0]:.1f} {a[1]:.1f}L{d[0]:.1f} {d[1]:.1f}',RUST,2,True)
    s+=path(f'M{a[0]:.1f} {a[1]:.1f}L{b[0]:.1f} {b[1]:.1f}L{d[0]:.1f} {d[1]:.1f}',BLUE,1.6,True,'4 3')
    s+=f'<circle cx="{d[0]:.1f}" cy="{d[1]:.1f}" r="10" fill="none" stroke="{RUST}" stroke-width="1.8"/>'
    s+=tag(985,879,'DIRECT + REFLECTED PATHS',RUST,12)
    s+=text(985,1025,'Damage aligns with the lower-right area.',14,'italic',MUTED)

    s+=text(1286,886,'1. REGISTER → COMPARE',16,'sansbold',RUST)
    s+=body(1286,909,279,'The calibration photo unlocks six objects. Matching the standard layout releases the three process photos.',16,21)
    s+=text(1286,984,'2. BUILD → CALIBRATE',16,'sansbold',RUST)
    s+=body(1286,1007,279,'Match placement, rotation, intensity, warmth, aim, shadow and reflection.',16,21)

    s+=text(1592,886,'3. DAMAGE → RECORDS',16,'sansbold',RUST)
    s+=body(1592,909,278,'Only the solved actual scene reveals the damage clue, then access and report logs.',16,21)
    s+=text(1592,966,'18:20',15,'sansbold',BLUE)+text(1652,966,'Work registered complete',15,'sans')
    s+=text(1592,986,'22:46',15,'sansbold',RUST)+text(1652,986,'Restorer re-enters',15,'sans')
    s+=text(1592,1006,'22:59',15,'sansbold',RUST)+text(1652,1006,'Report changed to “cold light”',15,'sans')
    s+=text(1592,1026,'23:18',15,'sansbold',BLUE)+text(1652,1026,'Leaves; no other entry',15,'sans')
    s+='</g>'

    s+=rule(50,1040,1820,weight=1)
    s+=text(50,1056,'CASE 01 / Restore ten spatial relationships → photograph → archive → studio.',13,'sans',MUTED)
    s+=text(982,1056,'CASE 02 / Heat use + altered report → responsibility established → archive → ¥1,800.',13,'sans',RUST)
    s+='</svg>'
    (OUT/(STEM+'.svg')).write_text(s,encoding='utf-8')
    facts={
        'format':{'width':1920,'height':1080,'language':'English','text':'editable SVG','images':'embedded Blender render PNGs'},
        'accepted_spaces':['Player studio (hub)','Office (case 01)','Conservation / heritage restoration lab (case 02)'],
        'sources':['data/cases/office_case_001.json','data/cases/gallery_case_002.json','scripts/reconstruction_zone.gd','scripts/scene_clue_point.gd','scripts/reconstruction_manager.gd'],
        'assets':'whitebox/scene-calibration-whiteboxes.blend',
        'limitations':'Whiteboxes simplify geometry. Light arrows show evidence relationships, not a thermal simulation.',
        'unrelated_legacy_cases':'Excluded from this page; project data left unchanged.'
    }
    (OUT/(STEM+'-sources.json')).write_text(json.dumps(facts,indent=2),encoding='utf-8')
    print('Built '+STEM+'.svg')


if __name__=='__main__':build()
