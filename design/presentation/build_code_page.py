"""Build a native SVG code page using exact GDScript excerpts and Godot captures."""
from pathlib import Path
from html import escape
import hashlib
import json
import textwrap
from PIL import ImageFont
from build_pages import OUT, ROOT, FONT, INK, MUTED, RUST, paper, text, paragraph, rule, uri

STEM = '05-code-architecture'
REPO = 'https://github.com/rexgame103-maker/scene-calibration'
CAPTURES = OUT / 'code/screenshots'
SOURCE_RECORDS = []


def linked(svg, target):
    target = escape(target, quote=True)
    return f'<a href="{target}" xlink:href="{target}">{svg}</a>'


def excerpt(path, first, last, x, y, width, heading):
    source = ROOT / path
    lines = source.read_text(encoding='utf-8').splitlines()
    selected = lines[first-1:last]
    display = textwrap.dedent('\n'.join(selected).expandtabs(4)).splitlines()
    link = f'{REPO}/blob/main/{path}#L{first}-L{last}'
    font_size = 15
    while font_size > 14 and max(ImageFont.truetype(str(FONT/'consola.ttf'),font_size).getlength(t) for t in display) > width-42:
        font_size -= 1
    font = ImageFont.truetype(str(FONT/'consola.ttf'),font_size)
    rows=[]
    for i,line in enumerate(display):
        pending=line
        label=str(first+i)
        while font.getlength(pending)>width-49:
            cut=max(j for j in range(1,len(pending)) if pending[j]==' ' and font.getlength(pending[:j])<=width-49)
            rows.append((label,pending[:cut]))
            pending='    '+pending[cut:].lstrip()
            label='↳'
        rows.append((label,pending))
    assert len(rows)<=9, path
    s = text(x,y-28,heading,13,'sansbold',RUST)
    s += f'<rect x="{x-5}" y="{y-20}" width="{width+8}" height="{len(rows)*21+18}" fill="#eae2d2" opacity=".66"/>'
    s += f'<path d="M{x-5} {y-20}v{len(rows)*21+18}" stroke="{INK}" stroke-width="2"/>'
    for i,(label,line) in enumerate(rows):
        yy=y+i*21
        s += text(x+23,yy,label,11,'sans',MUTED,'end')
        s += text(x+39,yy,line,font_size,'code',INK,extra=f'xml:space="preserve" data-column-x="{x+39}" data-column-width="{width-35}"')
    label=path.removeprefix('scripts/')+f' / L{first}–{last}'
    s += linked(text(x,y+198,label,13,'sans',MUTED),link)
    SOURCE_RECORDS.append({'file':path,'sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
                           'lines':[first,last],'original_lines':selected,'display_lines':display,
                           'display_normalization':'Tabs expanded to four spaces; common indentation removed. Long lines visually wrap, marked by an arrow instead of a new source line number.',
                           'url':link,'font_size':font_size})
    return s


def photograph(id,x,y,w,viewbox=None):
    path=CAPTURES/(id+'.png')
    h=w*9/16
    u=uri(path)
    s=f'<g id="capture-{id}"><rect x="{x-4}" y="{y-4}" width="{w+8}" height="{h+8}" fill="#fff9ec" stroke="{INK}" stroke-width="1"/>'
    if viewbox:
        s+=f'<svg x="{x}" y="{y}" width="{w}" height="{h}" viewBox="{viewbox}" overflow="hidden">'
        s+=f'<image width="1600" height="900" href="{u}" xlink:href="{u}"/></svg>'
    else:
        s+=f'<image x="{x}" y="{y}" width="{w}" height="{h}" preserveAspectRatio="xMidYMid meet" href="{u}" xlink:href="{u}"/>'
    s+='</g>'
    SOURCE_RECORDS.append({'image':str(path.relative_to(OUT)).replace('\\','/'),
                           'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
                           'origin':'Godot 4.7.2 runtime screenshot','crop_viewbox':viewbox})
    return s


def feature(x,y,number,title,image_id,caption,code_file,start,end,function,body,crop=None):
    s=f'<g id="feature-{number}">'
    s+=text(x,y,number,26,'italic',RUST)
    s+=text(x+46,y,title,29,'bold')
    s+=photograph(image_id,x+4,y+27,388,crop)
    s+=text(x+4,y+267,caption,14,'italic',MUTED)
    s+=excerpt(code_file,start,end,x+420,y+75,468,function)
    # A small connector ties the observed screen to its code without crossing text.
    s+=f'<path d="M{x+399} {y+131}h13m-5 -4 5 4-5 4" fill="none" stroke="{RUST}" stroke-width="1.6"/>'
    p,last=paragraph(x+4,y+301,883,body,18,24,'serif')
    assert last<=y+326
    s+=p+'</g>'
    return s


def build():
    s=paper('Scene Calibration — Code & Architecture',
        'English 1920 by 1080 newspaper code page. Four actual GDScript excerpts paired with runtime Godot screenshots: evidence, visible clues, reconstruction and desktop windows. All code and text remain editable. The public repository and source guide are linked.')
    s=s.replace('</style>', '.code{font-family:Consolas,"Courier New",monospace;font-kerning:none;font-variant-ligatures:none}</style>')
    s+=text(50,46,'SCENE CALIBRATION / DESIGN DOSSIER',15,'sansbold')
    s+=text(1870,46,'NO. 05 / CODE & ARCHITECTURE',15,'sans',anchor='end')
    s+=rule(50,59,1820,weight=1.2)
    s+=text(50,124,'THE SYSTEM BEHIND THE SCENE',58,'bold')
    s+=text(51,160,'From a photograph to a restored room: the code that makes spatial deduction playable.',22,'italic',MUTED)
    s+=rule(50,178,1820,RUST,4)
    s+=text(50,205,'PUBLIC REPOSITORY / COMPLETE GODOT PROJECT',13,'sansbold',RUST)
    s+=linked(text(50,235,'github.com/rexgame103-maker/scene-calibration',25,'sansbold'),REPO)
    s+=linked(text(51,258,'SOURCE GUIDE  ↗',13,'sansbold',RUST),REPO+'/blob/main/docs/CODE_REVIEW.md')
    s+=text(218,258,'Scenes / scripts / case data / shaders / assets / offline source browser',14,'sans',MUTED)
    s+=text(1230,205,'REVIEW ROUTE',13,'sansbold',RUST)
    s+=text(1230,229,'README → Code Review → Source Files',19,'sansbold')
    s+=text(1230,254,'Godot 4.7 / GDScript / Player studio + two cases',16,'sans',MUTED)
    s+=rule(50,279,1820,weight=.9)
    s+=feature(50,317,'01','Evidence becomes inventory','evidence',
        'OFFICE / The first photograph reveals three objects.',
        'scripts/case_manager.gd',197,205,'view_evidence()',
        'Viewing a photograph records its state and discovers its linked clues. The unlock evaluator then checks those clues and releases the matching furniture into the inventory.')
    s+=feature(979,317,'02','Observe before you investigate','visible-clue',
        'OFFICE / Rotate to expose the worn side of the desk.',
        'scripts/scene_clue_point.gd',194,199,'_is_runtime_visible()',
        'The same visibility gate controls both the marker and investigation. Camera frustum, surface angle and rendered-mesh occlusion are checked, so a hidden scratch cannot be clicked through an object.',
        '245 250 1100 618.75')
    s+=rule(50,661,1820,weight=.8,opacity=.5)
    s+=f'<path d="M959 294v356m0 341v-307" stroke="{INK}" stroke-width=".6" opacity=".35"/>'
    s+=feature(50,710,'03','Reconstruct the relationships','reconstruction',
        'RESTORATION / Furniture placement + light calibration.',
        'scripts/reconstruction_zone.gd',97,104,'contains_furniture()',
        'Positions are evaluated in each zone’s local space; orientation is checked separately. A step also requires its clues and lighting conditions, including lamp settings, shadow projection and reflection.')
    s+=feature(979,710,'04','A desktop with real windows','desktop',
        'STUDIO / Mail runs inside an independent application window.',
        'scripts/terminal_app_window.gd',73,79,'toggle_maximized()',
        'Maximize stores the original bounds and restore returns to them. Dragging, minimizing, taskbar activation and closing retain the correct app state; reading a message clears its unread dot.')
    s+=rule(50,1047,1820,weight=1)
    s+=text(50,1059,'ACTUAL SOURCE EXCERPTS / IN-GAME CAPTURES / SIX TARGETED SMOKE CHECKS PASSED',12,'sans',MUTED)
    s+=text(1870,1059,'PUBLIC SOURCE / 09 OCT 2026 / 05',12,'sansbold',MUTED,'end')
    s+='</svg>'
    (OUT/(STEM+'.svg')).write_text(s,encoding='utf-8')
    manifest={'page':{'width':1920,'height':1080,'language':'English','text':'editable native SVG'},
              'repository':REPO,'code_reference':'main branch line links; source hashes below identify the represented files',
              'capture_script':'code/capture_code_features.gd',
              'capture_method':'Isolated Godot project/user directory, English, 1600×900. Existing debug placement/calibration helpers stage the cases. The office clue passes the real camera visibility gate; the restoration case passes its final reconstruction conditions. No game scene files were edited.',
              'sources':SOURCE_RECORDS}
    (OUT/(STEM+'-sources.json')).write_text(json.dumps(manifest,indent=2,ensure_ascii=False),encoding='utf-8')
    print('Built '+STEM+'.svg with '+str(sum('file' in r for r in SOURCE_RECORDS))+' exact source excerpts')


if __name__=='__main__':build()
