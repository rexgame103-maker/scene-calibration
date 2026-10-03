"""Compose editable SVG previews from the supplied atlas; no game files are changed."""
from pathlib import Path
import base64
from html import escape

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[1]
ATLAS = ROOT / 'assets/ui/case_briefing_newspaper/newspaper_modules.png'
PHOTO = ROOT / 'assets/case_photos/office/concept_workstation.png'

def uri(path):
    return 'data:image/png;base64,' + base64.b64encode(path.read_bytes()).decode()

def module(region, box, opacity=1):
    sx, sy, sw, sh = region
    x, y, w, h = box
    return f'<svg x="{x}" y="{y}" width="{w}" height="{h}" viewBox="{sx} {sy} {sw} {sh}" preserveAspectRatio="none" overflow="hidden" opacity="{opacity}"><use href="#atlas"/></svg>'

def text(x, y, content, size=20, fill='#302820', family='sans', weight=400, extra=''):
    return f'<text x="{x}" y="{y}" font-size="{size}" fill="{fill}" class="{family}" font-weight="{weight}" {extra}>{escape(content)}</text>'

def rule(x, y, w, color='#6c5c49', opacity=.5):
    return f'<path d="M{x} {y}h{w}" stroke="{color}" opacity="{opacity}"/>'

def paper():
    # Keep the original outer frame proportions. Cover only its baked-in rules
    # with naturally scaled blank paper, so no rule crosses editable text.
    return module((28,364,710,445),(380,48,1176,802)) + '<rect x="443" y="113" width="1060" height="697" fill="url(#paperGrain)"/>'

def button(x,y,w,h,label,selected=False,sub=None):
    region=(1168,457,350,88) if selected else (459,832,312,83)
    s=module(region,(x,y,w,h))
    ink='#f0e5d2' if selected else '#3e3328'
    s+=text(x+26,y+(34 if sub else h/2+7),label,19,ink,weight=600)
    if sub: s+=text(x+26,y+61,sub,13,'#c7bba7' if selected else '#796a56')
    return s

def photo_mount():
    # Nine-slice a supplied blank frame; never enlarge its border thickness.
    sx,sy,sw,sh=462,924,299,61
    x,y,w,h=435,330,694,464
    b=12
    srcx=[sx,sx+b,sx+sw-b]; srcy=[sy,sy+b,sy+sh-b]
    dstx=[x,x+b,x+w-b]; dsty=[y,y+b,y+h-b]
    return ''.join(module((srcx[i],srcy[j],[b,sw-2*b,b][i],[b,sh-2*b,b][j]),(dstx[i],dsty[j],[b,w-2*b,b][i],[b,h-2*b,b][j])) for j in range(3) for i in range(3))

def compose(mode):
    photo=mode=='photo'
    s=f'''<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1600" height="900" viewBox="0 0 1600 900">
<title>案件资料 · {'现场照片' if photo else '案情描述'}</title>
<defs><image id="atlas" width="1536" height="1024" href="{uri(ATLAS)}"/>
<radialGradient id="desk"><stop stop-color="#302c24"/><stop offset="1" stop-color="#12110e"/></radialGradient>
<filter id="shadow" x="-20%" y="-20%" width="140%" height="140%"><feDropShadow dx="0" dy="12" stdDeviation="14" flood-opacity=".38"/></filter>
<pattern id="paperGrain" width="1060" height="380" patternUnits="userSpaceOnUse">{module((70,646,630,113),(0,0,1060,190))}<g transform="translate(0 380) scale(1 -1)">{module((70,646,630,113),(0,0,1060,190))}</g></pattern>
<style>.sans{{font-family:'Microsoft YaHei','Noto Sans CJK SC',sans-serif}}.serif{{font-family:'SimSun','Noto Serif CJK SC',serif}}.latin{{font-family:Georgia,serif}}</style></defs>
<rect width="1600" height="900" fill="url(#desk)"/>
'''
    s+=text(48,76,'案件资料',38,'#e9dec9','serif',700)
    s+=text(50,105,'CASE ARCHIVE  /  BF–071',12,'#a89b85','latin',extra='letter-spacing="2"')
    s+=rule(50,132,275,'#b09b7e',.4)
    s+=text(50,179,'蓝色文档失踪案',25,'#e9dec9','serif',700)
    s+=text(50,211,'恢复被提前清空的办公室',15,'#a99e8c')
    s+=button(45,254,292,55,'全部资料')
    s+=text(301,290,'⌄',21,'#6b5b46')
    s+=button(45,335,292,86,'清空前照片',photo,'01   /   邮件附件 · 现场照片')
    s+=button(45,438,292,86,'警局委托说明',not photo,'02   /   案情描述')
    s+=text(54,572,'2 份资料',13,'#9d907b')
    s+=button(45,786,292,57,'←   返回现场')
    s+=text(284,821,'Esc',12,'#75644f','latin')
    s+='<g filter="url(#shadow)">'+paper()+'</g>'
    s+=text(449,139,'现场档案',17,'#665440','serif',700)
    s+=text(449,163,'CITY INVESTIGATION BUREAU',11,'#76644d','latin',extra='letter-spacing="1.4"')
    s+=module((770,258,492,64),(1162,115,315,41),.83)
    s+=text(1478,179,'BF–071  /  '+('01' if photo else '02'),12,'#76644d','latin',extra='text-anchor="end" letter-spacing="1.5"')
    s+=rule(449,193,1030)
    s+=text(449,226,'现场照片' if photo else '案情描述',14,'#874b3c',weight=600,extra='letter-spacing="3"')
    s+=text(449,279,'邮件附件 · 清空前照片' if photo else '警局委托说明',40,'#29241e','serif',700)
    s+=module((770,352,300,15),(449,299,1028,5))
    if photo:
        # A supplied blank paper module forms the photograph's mount.
        s+=photo_mount()
        s+=f'<image x="453" y="348" width="658" height="405" preserveAspectRatio="xMidYMid meet" href="{uri(PHOTO)}"/>'
        s+=text(782,778,'报警人提供 · 办公区旧照',14,'#6b5c48','serif',extra='text-anchor="middle"')
        s+=text(1170,373,'照片说明',21,'#302820','serif',700)
        for i,line in enumerate(['照片能确认办公桌、办公椅','与桌面电脑，但右侧区域','被画面裁掉。']):
            s+=text(1170,418+i*35,line,18)
        s+=rule(1170,536,290)
        s+=text(1170,574,'已获得 3 条线索',18,'#526047',weight=600)
        s+=text(1170,604,'家具栏已更新',15,'#68705b')
        s+=text(1170,720,'01 / 02',12,'#7c6c56','latin',extra='letter-spacing="2"')
    else:
        for y,line in [(395,'现场在警方抵达前被清空。'),(458,'委托只要求恢复空间关系，'),(503,'清空者身份暂不在本次调查范围内。')]:
            s+=text(461,y,line,28,'#32291f','serif')
        s+=rule(460,564,988)
        s+=text(460,612,'该资料已查看，没有发现新的线索。',16,'#776a56')
        s+=text(1476,744,'02 / 02',12,'#7c6c56','latin',extra='text-anchor="end" letter-spacing="2"')
    s+=text(1477,789,'CASE FILE  /  BF–071',10,'#7c6c56','latin',extra='text-anchor="end" letter-spacing="1.5"')
    return s+'</svg>'

for mode in ['photo','text']:
    (OUT/f'case_files_{mode}.svg').write_text(compose(mode),encoding='utf-8')
(OUT/'preview.html').write_text('''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><title>案件资料 · 报纸 UI 预览</title><style>body{margin:0;background:#15130f;color:#e9dec9;font:15px "Microsoft YaHei",sans-serif}nav{height:60px;display:flex;align-items:center;gap:12px;padding:0 24px}button{background:#e8dac1;border:0;padding:10px 22px;cursor:pointer;color:#33291f}img{display:block;width:100%;height:auto}span{margin-left:15px;opacity:.65}</style><nav><button onclick="document.querySelector('img').src='case_files_photo.svg'">现场照片</button><button onclick="document.querySelector('img').src='case_files_text.svg'">案情描述</button><span>案件资料 / 报纸模块预览</span></nav><img src="case_files_photo.svg"></html>''',encoding='utf-8')
print(OUT)
