"""Dense newspaper code plate: six systems, selected exact lines, native SVG text."""
from html import escape
import hashlib
import json
from PIL import ImageFont
from build_pages import OUT, ROOT, FONT, INK, MUTED, RUST, paper, text, paragraph, rule, uri

STEM = '05-code-architecture'
REPO = 'https://github.com/rexgame103-maker/scene-calibration'
CAPTURES = OUT / 'gameplay/screenshots'
RECORDS = []
SOURCE_LINES = 0

def linked(svg, target):
    target = escape(target, quote=True)
    return f'<a href="{target}" xlink:href="{target}">{svg}</a>'

def snippet(path, ranges, x, y, w, size=14, leading=17, highlight=()):
    """Keep source numbers; mark every omitted range and visual continuation."""
    global SOURCE_LINES
    raw=(ROOT/path).read_bytes()
    all_lines=raw.decode('utf-8').splitlines()
    selected=[(n,all_lines[n-1]) for a,b in ranges for n in range(a,b+1)]
    nonblank=[v.expandtabs(4) for _,v in selected if v.strip()]
    indent=min(len(v)-len(v.lstrip()) for v in nonblank)
    font=ImageFont.truetype(str(FONT/'consola.ttf'),size)
    rows=[];previous=None
    for number,line in selected:
        if previous is not None and number!=previous+1:
            rows.append(('…','… omitted source lines …',None))
        previous=number
        content=line.expandtabs(4)[indent:]
        if not content.strip():
            rows.append(('', '',number));continue
        label=str(number)
        while font.getlength(content)>w-52:
            # Skip leading indentation as a wrap point: it would make no progress
            # when a long identifier is wider than a narrow newspaper column.
            spaces=[i for i,c in enumerate(content) if c==' ' and content[:i].strip() and font.getlength(content[:i])<=w-52]
            cut=max(spaces) if spaces else max(i for i in range(1,len(content)) if font.getlength(content[:i])<=w-52)
            rows.append((label,content[:cut],number))
            content='    '+content[cut:].lstrip();label='↳'
        rows.append((label,content,number))
    s=f'<g id="code-{path.split("/")[-1].split(".")[0]}-{ranges[0][0]}">'
    s+=f'<path d="M{x+29} {y-13}v{len(rows)*leading}" stroke="{INK}" stroke-width=".6" opacity=".3"/>'
    for i,(number,value,source_line) in enumerate(rows):
        yy=y+i*leading
        if source_line in highlight:
            s+=f'<rect x="{x+33}" y="{yy-12}" width="{w-33}" height="{leading}" fill="{RUST}" opacity=".11"/>'
        s+=text(x+23,yy,number,10,'sans',MUTED,'end')
        s+=text(x+39,yy,value,size,'code',MUTED if source_line is None else INK,extra=f'xml:space="preserve" data-column-x="{x+39}" data-column-width="{w-35}"')
    bottom=y+(len(rows)-1)*leading
    link=f'{REPO}/blob/main/{path}#L{min(a for a,b in ranges)}-L{max(b for a,b in ranges)}'
    label=path.removeprefix('scripts/')+' / '+', '.join(f'{a}–{b}' for a,b in ranges)
    s+=linked(text(x,bottom+22,label,11,'sans',MUTED),link)+'</g>'
    RECORDS.append({'file':path,'sha256':hashlib.sha256(raw).hexdigest(),'ranges':ranges,'original_lines':[{'line':n,'text':v} for n,v in selected],'url':link,'display':'Tabs expanded to four spaces; common indentation removed. Explicit gaps and continuation arrows preserve original source line numbering.','font_size':size,'rendered_rows':len(rows)})
    SOURCE_LINES+=len(selected)
    return s,bottom+22

def photo(id,x,y,w,angle=0,crop=None):
    p=CAPTURES/(id+'.png');u=uri(p);h=w*9/16
    s=f'<g transform="rotate({angle} {x+w/2} {y+h/2})" aria-label="Godot capture: {id}">'
    s+=f'<rect x="{x-4}" y="{y-4}" width="{w+8}" height="{h+8}" fill="#fff9ee" stroke="{INK}" stroke-width=".8"/>'
    if crop:
        s+=f'<svg x="{x}" y="{y}" width="{w}" height="{h}" viewBox="{crop}" overflow="hidden"><image width="1600" height="900" href="{u}" xlink:href="{u}"/></svg>'
    else:
        s+=f'<image x="{x}" y="{y}" width="{w}" height="{h}" href="{u}" xlink:href="{u}"/>'
    s+='</g>'
    RECORDS.append({'image':str(p.relative_to(OUT)).replace('\\','/'),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'origin':'Fresh Godot runtime capture','crop_viewbox':crop})
    return s

def heading(x,y,n,title,size=24):
    return text(x,y,n,20,'italic',RUST)+text(x+37,y,title,size,'bold')

def build():
    s=paper('Scene Calibration — Core Code & Implementation','Dense, asymmetric English newspaper code page: six implemented systems, exact GDScript source excerpts and four small in-game photographs. Source gaps and visual wrapping are explicit. Editable text and linked public source files.')
    s=s.replace('</style>','.code{font-family:Consolas,"Courier New",monospace;font-kerning:none;font-variant-ligatures:none}</style>')
    s+=text(50,46,'SCENE CALIBRATION / DESIGN DOSSIER',15,'sansbold')+text(1870,46,'NO. 05 / SOURCE & IMPLEMENTATION',15,'sans',anchor='end')+rule(50,59,1820)
    s+=text(50,122,'INSIDE THE INVESTIGATION',58,'bold')+text(52,151,'Six connected systems. One evidence-driven reconstruction loop.',21,'italic',MUTED)
    s+=linked(text(1870,105,'PUBLIC SOURCE  ↗',14,'sansbold',RUST,'end'),REPO)
    s+=linked(text(1870,132,'github.com/rexgame103-maker/scene-calibration',17,'sans',INK,'end'),REPO)
    s+=linked(text(1870,154,'CODE REVIEW / DIRECTORY MAP  ↗',12,'sansbold',MUTED,'end'),REPO+'/blob/main/docs/CODE_REVIEW.md')+rule(50,174,1820,RUST,3.5)
    stages=[('01 / OBSERVE','Camera + surface + occlusion'),('02 / UNLOCK','Evidence → clues → furniture'),('03 / RECONSTRUCT','Zones + orientation + lighting'),('04 / OPERATE','Desktop + application windows'),('05 / ARCHIVE','Persistent state + saved photos')]
    for i,(name,desc) in enumerate(stages):
        x=50+i*367
        s+=text(x,195,name,13,'sansbold',RUST)+text(x,215,desc,15,'sans')
        if i<4:s+=f'<path d="M{x+329} 197h22m-5 -4 5 4-5 4" fill="none" stroke="{MUTED}" stroke-width="1.2"/>'
    s+=rule(50,229,1820,weight=.65)+f'<path d="M819 242v790m610 -771v770" stroke="{INK}" stroke-width=".7" opacity=".38"/>'
    s+=heading(50,268,'01','Seeing is a condition',29)
    p,_=paragraph(50,300,483,'A clue must face the camera and remain unoccluded. Both its glow and the click use this same gate.',17,23);s+=p
    s+=photo('inspection',626,248,170,-2,'245 250 1100 618.75')+text(50,357,'scene_clue_point.gd / is_visible_from_camera()',12,'sansbold',RUST)
    a,bottom=snippet('scripts/scene_clue_point.gd',[(202,212),(215,217),(230,234)],50,372,746,13,15,(211,232,233));s+=a
    s+=text(50,bottom+25,'Surface normal → facing test → triangle intersection → valid investigation.',15,'italic',MUTED)+rule(50,745,746,weight=.8,opacity=.5)
    s+=heading(50,772,'02','Evidence releases furniture',26)
    p,_=paragraph(50,804,542,'JSON requirements support all / any clue rules. Unlock once; notify the inventory through a signal.',16,21);s+=p
    s+=photo('evidence',640,761,157,2)+text(50,844,'case_manager.gd / _evaluate_furniture_unlocks()',12,'sansbold',RUST)
    a,end=snippet('scripts/case_manager.gd',[(254,256),(259,265)],50,861,746,14,16,(261,263,265));s+=a
    assert end<1045,('unlock',end)
    s+=heading(843,280,'03','A step needs proof',25)
    p,_=paragraph(843,310,363,'A correct layout is only part of the answer. Required clues and lighting must agree.',16,21);s+=p
    s+=photo('calibration',1223,261,187,1.8)+text(843,379,'reconstruction_manager.gd / is_step_satisfied()',12,'sansbold',RUST)
    a,end=snippet('scripts/reconstruction_manager.gd',[(105,116)],843,403,567,13,15,(109,114,116));s+=a
    assert end<716,('reconstruction',end)
    s+=rule(843,671,567,weight=.8,opacity=.5)+heading(843,704,'04','Light becomes evidence',25)
    s+=text(843,733,'Check the lamp’s aim, then estimate its projected shadow.',15,'italic',MUTED)+text(843,757,'_is_shadow_projection_condition_satisfied()',12,'sansbold',RUST)
    a,end=snippet('scripts/reconstruction_manager.gd',[(261,273)],843,779,567,13,15,(264,272,273));s+=a
    assert end<1045,('lighting',end)
    s+=heading(1453,263,'05','Windows that work',23)+photo('mail',1662,294,198,-1.6)
    p,_=paragraph(1453,298,189,'Store normal bounds. Maximize, restore, drag or minimize. Each app retains its own state.',16,21);s+=p
    s+=text(1453,433,'terminal_app_window.gd',12,'sansbold',RUST)
    a,end=snippet('scripts/terminal_app_window.gd',[(72,78),(81,88)],1453,458,417,13,15,(75,76,83,87,88));s+=a
    assert end<810,('desktop',end)
    s+=rule(1453,747,417,weight=.8,opacity=.5)+heading(1453,780,'06','State survives a session',21)
    s+=text(1453,805,'Reading updates mail; JSON preserves the profile.',13,'italic',MUTED)
    a,end=snippet('scripts/player_profile.gd',[(175,180),(103,108)],1453,826,417,13,13,(177,179,103,107));s+=a
    assert end<1045,('save',end)
    s+=rule(50,1047,1820)+text(50,1059,f'ACTUAL GDSCRIPT / {SOURCE_LINES} SELECTED SOURCE LINES / … MARKS GAPS / ↳ MARKS VISUAL WRAP',12,'sans',MUTED)+text(1870,1059,'GODOT CAPTURES / EDITABLE VECTOR TEXT / 05',12,'sansbold',MUTED,'end')+'</svg>'
    (OUT/(STEM+'.svg')).write_text(s,encoding='utf-8')
    manifest={'page':{'width':1920,'height':1080,'language':'English','text':'editable native SVG'},'repository':REPO,'systems':6,'selected_source_lines':SOURCE_LINES,'capture_script':'gameplay/capture_gameplay_sequence.gd','code_reference':'Current source; original line numbers, hashes and explicit gaps recorded below. Links target GitHub main.','sources':RECORDS}
    (OUT/(STEM+'-sources.json')).write_text(json.dumps(manifest,indent=2,ensure_ascii=False),encoding='utf-8')
    print(f'Built {STEM}.svg: {SOURCE_LINES} source lines, six systems, four runtime photographs')

if __name__=='__main__':build()
