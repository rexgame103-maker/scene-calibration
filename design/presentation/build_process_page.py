"""Four-stage production plate: nine Blender studies + three Godot captures."""
from html import escape
from pathlib import Path
import json
from build_pages import OUT, INK, MUTED, RUST, uri, text, rule, paper, measure

STEM='04-production-process'
PROCESS=OUT/'process'
SOURCES=[]


def picture(id,stage,x,y,w,tag):
    p=PROCESS/('renders' if stage<4 else 'final')/(f'{id}-stage-{stage}.png' if stage<4 else f'{id}-final.png')
    source=f'Blender reconstructed study: {id}, stage {stage}' if stage<4 else f'Godot in-engine capture: {id}'
    SOURCES.append({'cell':tag,'image':str(p.relative_to(OUT)).replace('\\','/'),'origin':source})
    u=uri(p);h=w*750/1200
    s=f'<g id="{id}-stage-{stage}" aria-label="{escape(source)}">'
    s+=f'<rect x="{x-3}" y="{y-3}" width="{w+6}" height="{h+6}" fill="#fff9ed" stroke="{INK}" stroke-width=".75"/>'
    s+=f'<image x="{x}" y="{y}" width="{w}" height="{h}" preserveAspectRatio="xMidYMid meet" href="{u}" xlink:href="{u}"/>'
    s+=f'<rect x="{x+7}" y="{y+7}" width="31" height="21" fill="#f8f0e0" opacity=".9"/>'
    s+=text(x+22.5,y+22,tag,12,'sansbold',RUST,'middle')
    s+='</g>'
    return s


def build():
    s=paper('Scene Calibration — Production Process',
            'A 1920 by 1080 English newspaper production plate. The player studio, office and heritage restoration room are each shown in four steps: single-box blockout, form and structure, detailed clay study, final Godot lighting capture. The first three steps are newly reconstructed in Blender, not recovered historical stages. All twelve images are embedded; all text remains editable.')
    s+=text(50,46,'SCENE CALIBRATION / DESIGN DOSSIER',15,'sansbold')
    s+=text(1870,46,'NO. 04 / ENVIRONMENT PRODUCTION',15,'sans',anchor='end')
    s+=rule(50,59,1820,weight=1.2)
    s+=text(50,128,'FROM BLOCKOUT TO ATMOSPHERE',62,'bold')
    s+=text(51,161,'Three environments. Four stages. Establish the space, refine the objects, then shape the mood.',22,'italic',MUTED)
    s+=rule(50,175,1820,RUST,4)
    cols=[205,625,1045,1465]
    headings=['01 / BLOCKOUT','02 / FORM & STRUCTURE','03 / DETAIL PASS','04 / FINAL LIGHTING']
    hints=['One object = one box. No parts.','Silhouettes, supports and openings.','Joinery, props and surface cues.','Complete scenes captured in Godot.']
    for x,heading,hint in zip(cols,headings,hints):
        s+=text(x,201,heading,21,'bold')
        s+=text(x,220,hint,14,'sans',MUTED)
    for x in (607,1027,1447):
        s+=f'<path d="M{x} 193h10m-4 -4 4 4-4 4" fill="none" stroke="{RUST}" stroke-width="1.4"/>'
    rows=[('studio',236,'A'),('office',510,'B'),('restoration',784,'C')]
    for id,y,letter in rows:
        s+=f'<g id="row-{id}">'
        mid=y+128
        s+=text(50,y+23,letter,35,'italic',RUST)
        if id=='studio':
            s+=text(50,mid-23,'PLAYER',22,'bold')
            s+=text(50,mid+7,'STUDIO',22,'bold')
            s+=text(51,mid+39,'Investigation hub',14,'italic',MUTED)
            s+=text(51,mid+64,'Work + archive',13,'sans',MUTED)
        elif id=='office':
            s+=text(50,mid-10,'OFFICE',24,'bold')
            s+=text(51,mid+20,'CASE 01',14,'sansbold',RUST)
            s+=text(51,mid+49,'Space + traces',14,'italic',MUTED)
        else:
            s+=text(50,mid-26,'RESTORATION',16,'sansbold')
            s+=text(50,mid+5,'ROOM',25,'bold')
            s+=text(51,mid+34,'CASE 02',14,'sansbold',RUST)
            s+=text(51,mid+63,'Light + evidence',14,'italic',MUTED)
        for i,x in enumerate(cols,1):s+=picture(id,i,x,y,405,letter+str(i))
        s+='</g>'
    s+=rule(50,498,1820,weight=.85,opacity=.45)
    s+=rule(50,773,1820,weight=.85,opacity=.45)
    s+=rule(50,1047,1820,weight=1)
    s+=text(50,1059,'01–03 / RECONSTRUCTED BLENDER STUDIES     ·     04 / IN-ENGINE GODOT CAPTURES',12,'sans',MUTED)
    s+=text(1870,1059,'THREE SPACES / TWELVE VIEWS / 04',12,'sansbold',MUTED,'end')
    s+='</svg>'
    (OUT/(STEM+'.svg')).write_text(s,encoding='utf-8')
    manifest={'format':{'width':1920,'height':1080,'language':'English','text':'editable SVG'},
              'images':SOURCES,'blender_source':'process/three-scenes-production-studies.blend',
              'build_source':'process/build_process_whiteboxes.py',
              'capture_source':'process/capture_final_scenes.gd',
              'stages_1_to_3':'Retrospective reconstructions created for this presentation; not recovered historical asset versions.',
              'stage_4':'Fresh screenshots from the three full authored Godot game scenes, retaining their saved lighting and materials. Camera framing is adjusted only in memory to include the complete rooms.'}
    (OUT/(STEM+'-sources.json')).write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    print('Built '+STEM+'.svg')


if __name__=='__main__':build()
