"""Final newspaper spread: fresh engine captures and a readable asymmetric flow."""
from html import escape
import hashlib
import json
from build_pages import OUT, INK, MUTED, RUST, paper, text, paragraph, rule, uri

STEM = '06-gameplay-demonstration'
CAPTURES = OUT / 'gameplay/screenshots'
RECORDS = []

def photograph(name, x, y, w, angle=0, h=None, crop=None):
    path = CAPTURES / (name + '.png')
    data = uri(path)
    h = h or w * 9 / 16
    s = f'<g id="photo-{name}" transform="rotate({angle} {x+w/2} {y+h/2})">'
    s += f'<rect x="{x-6}" y="{y-6}" width="{w+12}" height="{h+12}" fill="#fffaf0" stroke="{INK}" stroke-width=".9"/>'
    if crop:
        s += f'<svg x="{x}" y="{y}" width="{w}" height="{h}" viewBox="{crop}" preserveAspectRatio="xMidYMid slice" overflow="hidden"><image width="1600" height="900" href="{data}" xlink:href="{data}"/></svg>'
    else:
        s += f'<image x="{x}" y="{y}" width="{w}" height="{h}" href="{data}" xlink:href="{data}"/>'
    s += '</g>'
    RECORDS.append({'image':str(path.relative_to(OUT)).replace('\\','/'), 'sha256':hashlib.sha256(path.read_bytes()).hexdigest(), 'source':'Actual Godot 4.7.2 Windows OpenGL runtime', 'crop_viewbox':crop, 'rotation_degrees':angle})
    return s

def stage(x, y, number, title, copy, width=325):
    s = text(x,y,number,23,'italic',RUST) + text(x+40,y,title,24,'bold')
    p,end = paragraph(x,y+27,width,copy,17,22)
    return s+p,end

def arrow(path, muted=False):
    return f'<path d="{path}" fill="none" stroke="{MUTED if muted else RUST}" stroke-width="1.4" marker-end="url(#flow-arrow)" stroke-linecap="round"/>'

def build():
    s = paper('Scene Calibration — Gameplay Demonstration','Final English newspaper page with eight fresh screenshots from the real game. A dominant restored-office photograph and numbered smaller captures explain accepting an assignment, reading evidence, placing furniture, investigating traces, submitting and archiving. The restoration-room lighting case is a separate continuation.')
    s += f'<defs><marker id="flow-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M1 1 9 5 1 9" fill="none" stroke="{RUST}" stroke-width="1.2"/></marker></defs>'
    s += text(50,46,'SCENE CALIBRATION / DESIGN DOSSIER',15,'sansbold') + text(1870,46,'NO. 06 / LIVE PLAY REPORT',15,'sans',anchor='end') + rule(50,59,1820)
    s += text(50,126,'A ROOM, RECONSTRUCTED.',62,'bold')
    s += text(52,161,'From the studio inbox to an archived reconstruction. Two cases, one evidence loop.',22,'italic',MUTED)
    s += text(1870,111,'ACTUAL GAME CAPTURES',14,'sansbold',RUST,'end') + text(1870,139,'GODOT 4.7 / WINDOWS',14,'sans',MUTED,'end')
    s += rule(50,184,1820,RUST,3)

    # Small opening images are intentionally staggered, with generous caption gaps.
    s += photograph('mail',58,219,325,-1.6)
    s += photograph('evidence',428,237,338,1.3)
    a,_ = stage(56,432,'01','Read the assignment','Open Mail in the studio. Accept the police request to enter the office.'); s += a
    a,_ = stage(430,456,'02','Cross-check the record','The attached photograph reveals clues and makes furniture available.',338); s += a
    s += arrow('M392 340h23')
    s += arrow('M779 443v71H225v7')

    s += photograph('placement',58,534,325,1.1)
    s += photograph('inspection',427,556,338,-1.5)
    a,_ = stage(56,754,'03','Place and orient','Drag furniture into the room. Bounds, overlap and orientation matter.'); s += a
    a,_ = stage(430,775,'04','Inspect what is visible','Rotate around the desk, reveal its worn side and collect the new clue.',338); s += a
    s += arrow('M395 648h20')

    # The image is a runtime frame: the only capture change was hiding its HUD.
    s += photograph('office-restored',821,221,1034,-.5,459,'100 105 1500 665.86')
    s += text(846,250,'CASE 01 / THE MISSING BLUE FILE',14,'sansbold','#eee6d4')
    s += text(853,723,'Separate clues. One coherent room.',34,'bold')
    p,_ = paragraph(853,754,1000,'The desk, chair, terminal, cabinets, printer and water dispenser form a consistent spatial arrangement. The office is ready for the reconstruction report.',19,26)
    s += p
    s += rule(841,802,1029,weight=.65,opacity=.45)

    # Completion returns to the hub, rather than ending on an isolated result screen.
    s += text(56,840,'05',23,'italic',RUST) + text(96,840,'Submit the reconstruction',22,'bold')
    s += photograph('settlement',58,866,315,-.8)
    s += text(438,847,'06',23,'italic',RUST) + text(478,847,'Archive in the studio',22,'bold')
    s += photograph('album',440,873,300,1)
    s += arrow('M785 805v46H395l-15 11')
    s += arrow('M388 956h36')

    # Case 02 is deliberately labelled as a distinct, more demanding continuation.
    s += text(838,827,'THE NEXT CASE / HERITAGE RESTORATION ROOM',13,'sansbold',RUST)
    s += text(838,869,'Light is part',35,'bold') + text(838,909,'of the answer.',35,'bold')
    p,_ = paragraph(838,941,543,'Match lamp direction, intensity and color temperature. Shadow and reflection conditions extend the same evidence-and-reconstruction loop.',18,25)
    s += p
    s += text(1473,817,'CASE 02 / LIGHT CALIBRATION',14,'sansbold',RUST)
    s += photograph('calibration',1478,836,368,-1.2)
    s += arrow('M1398 884h55')

    s += rule(50,1050,1820) + text(50,1061,'REAL ENGINE FRAMES / STUDIO → OFFICE → REPORT → ALBUM / RESTORATION ROOM CONTINUATION',11,'sans',MUTED)
    s += text(1870,1061,'EDITABLE SVG / 16:9 / 06',11,'sansbold',MUTED,'end') + '</svg>'
    (OUT/(STEM+'.svg')).write_text(s,encoding='utf-8')
    manifest = {'page':{'width':1920,'height':1080,'language':'English','text':'Editable native SVG','style':'Lightly aged newspaper'},'images':RECORDS,'capture_script':'gameplay/capture_gameplay_sequence.gd','capture_manifest':'gameplay/capture-manifest.json','method':'Fresh runtime images in an isolated user profile. Existing debug helpers stage furniture and lighting; placement bounds, camera visibility, final reconstruction, submission, photograph archive and studio return are checked against actual game code. The large office frame hides only the HUD. Crop and slight rotation are SVG layout operations, not generated or repainted scenes.','flow':{'office':['Read the assignment','Cross-check the record','Place and orient','Inspect what is visible','Submit the reconstruction','Archive in the studio'],'restoration_room':'A separately labelled second case adds light, shadow and reflection conditions.'}}
    (OUT/(STEM+'-sources.json')).write_text(json.dumps(manifest,indent=2,ensure_ascii=False),encoding='utf-8')
    print(f'Built {STEM}.svg: eight actual engine frames; six office stages and case 02 continuation')

if __name__ == '__main__':
    build()
