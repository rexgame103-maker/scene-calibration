"""Build self-contained 16:9 newspaper pages with editable SVG text.

Official screenshots stay unmodified and are embedded as raster images.
Pillow is used only to measure type; layout, paper and rules are native SVG.
"""
from pathlib import Path
from html import escape
import base64
import json
import random
from PIL import ImageFont

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[1]
REF = OUT / 'references'
INK = '#25241f'
MUTED = '#676052'
RUST = '#874637'
FONT = Path('C:/Windows/Fonts')
FONTS = {'serif': 'georgia.ttf', 'bold': 'georgiab.ttf', 'italic': 'georgiai.ttf',
         'sans': 'arial.ttf', 'sansbold': 'arialbd.ttf'}


def uri(path):
    mime = 'image/jpeg' if path.suffix.lower() in ('.jpg', '.jpeg') else 'image/png'
    return f'data:{mime};base64,' + base64.b64encode(path.read_bytes()).decode('ascii')


def measure(value, size, kind='serif'):
    return ImageFont.truetype(str(FONT / FONTS[kind]), size).getlength(value)


def wrap(value, width, size, kind='serif'):
    lines, line = [], ''
    for word in value.split():
        candidate = f'{line} {word}'.strip()
        if line and measure(candidate, size, kind) > width:
            lines.append(line)
            line = word
        else:
            line = candidate
    if line:
        lines.append(line)
    return lines


def text(x, y, value, size=20, kind='serif', fill=INK, anchor='start', extra=''):
    return (f'<text x="{x}" y="{y}" class="{kind}" font-size="{size}" fill="{fill}" '
            f'text-anchor="{anchor}" {extra}>{escape(value)}</text>')


def paragraph(x, y, width, value, size=20, leading=27, kind='serif', fill=INK):
    lines = wrap(value, width, size, kind)
    spans = ''.join(f'<tspan x="{x}" y="{y + i * leading}">{escape(line)}</tspan>'
                    for i, line in enumerate(lines))
    svg = (f'<text class="{kind}" font-size="{size}" fill="{fill}" '
           f'data-column-x="{x}" data-column-width="{width}">{spans}</text>')
    return svg, y + (len(lines) - 1) * leading


def rule(x, y, width, color=INK, weight=1, opacity=1):
    return f'<path d="M{x} {y}h{width}" fill="none" stroke="{color}" stroke-width="{weight}" opacity="{opacity}"/>'


def vertical(x, y, height, opacity=.6):
    return f'<path d="M{x} {y}v{height}" stroke="{INK}" stroke-width="1" opacity="{opacity}"/>'


def image(path, x, y, width, height, label, source=None):
    # All screenshots use their native 16:9 aspect ratio, without cropping.
    picture = (f'<g aria-label="{escape(label, quote=True)}">'
               f'<rect x="{x-4}" y="{y-4}" width="{width+8}" height="{height+8}" fill="none" stroke="{INK}" stroke-width="1.1"/>'
               f'<image x="{x}" y="{y}" width="{width}" height="{height}" '
               f'preserveAspectRatio="xMidYMid meet" href="{uri(path)}" xlink:href="{uri(path)}"/>'
               '</g>')
    if source:
        return f'<a href="{escape(source, quote=True)}" xlink:href="{escape(source, quote=True)}">{picture}</a>'
    return picture


def paper(title, description):
    rng = random.Random(11)
    dots = ''.join(f'<circle cx="{rng.randrange(256)}" cy="{rng.randrange(256)}" '
                   f'r="{rng.choice((.3, .4, .5, .6))}" fill="#89745c" opacity="{rng.choice((.06,.09,.12))}"/>'
                   for _ in range(130))
    return (f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
            f'width="1920" height="1080" viewBox="0 0 1920 1080" role="img">'
            f'<title>{escape(title)}</title><desc>{escape(description)}</desc>'
            '<defs><linearGradient id="paper" x2="0.16" y2="1">'
            '<stop stop-color="#f7f0e3"/><stop offset=".5" stop-color="#f6eedf"/>'
            '<stop offset="1" stop-color="#f2e9d8"/></linearGradient>'
            f'<pattern id="fibers" width="256" height="256" patternUnits="userSpaceOnUse">{dots}</pattern>'
            '<style>.serif{font-family:Georgia,"Times New Roman",serif}.bold{font-family:Georgia,"Times New Roman",serif;font-weight:700}'
            '.italic{font-family:Georgia,"Times New Roman",serif;font-style:italic}.sans{font-family:Arial,Helvetica,sans-serif}'
            '.sansbold{font-family:Arial,Helvetica,sans-serif;font-weight:700}text{font-kerning:normal}</style></defs>'
            '<g id="paper-background"><rect width="1920" height="1080" fill="url(#paper)"/>'
            '<rect width="1920" height="1080" fill="url(#fibers)"/>'
            f'<rect x="18" y="18" width="1884" height="1044" fill="none" stroke="{INK}" stroke-width="1.2" opacity=".85"/></g>')


COVER_BODY = ('Scene Calibration is a spatial deduction game about reconstructing places after the evidence has been disturbed. '
              'Work from a personal studio, compare photographs and records, and inspect traces on everyday objects. '
              'Restore furniture, lighting, and spatial relationships to test your deductions. '
              'Complete investigations, archive restored scenes, and equip your studio for the next case.')


def cover():
    s = paper('Scene Calibration — Cover', 'Editable 1920 by 1080 newspaper cover, with the original start-menu camera screenshot and English game overview.')
    s += '<g id="masthead">'
    s += rule(42, 43, 599, weight=1.2) + rule(42, 49, 599, opacity=.65)
    s += rule(1279, 43, 599, weight=1.2) + rule(1279, 49, 599, opacity=.65)
    s += text(960, 55, 'SPECIAL EDITION', 24, 'bold', anchor='middle', extra='letter-spacing="5"')
    s += text(960, 174, 'SCENE CALIBRATION', 143, 'bold', anchor='middle', extra='textLength="1796" lengthAdjust="spacingAndGlyphs"')
    s += text(960, 212, 'A SPATIAL DEDUCTION GAME', 25, 'serif', anchor='middle', extra='letter-spacing="4"')
    s += rule(48, 229, 1824, RUST, 6)
    s += text(960, 267, 'REBUILD THE SCENE. REVEAL THE TRUTH.', 33, 'bold', anchor='middle', extra='letter-spacing="1.4"')
    s += rule(48, 281, 1824) + '</g>'
    s += '<g id="studio-photograph">'
    s += image(ROOT / 'design/cover/start-camera-clean.png', 54, 302, 1104, 621, 'Actual start-menu camera view, no buttons or menu')
    s += '</g>' + vertical(1182, 298, 631)
    s += '<g id="game-overview">' + text(1210, 347, 'THE INVESTIGATION', 42, 'bold')
    s += rule(1210, 365, 655)
    p1, p2 = COVER_BODY.split('Restore furniture', 1)
    p2 = 'Restore furniture' + p2
    body, end = paragraph(1210, 410, 648, p1.strip(), 27, 38)
    s += body
    body, end = paragraph(1210, end + 66, 648, p2, 27, 38)
    s += body + '</g>'
    s += rule(48, 949, 1824) + rule(48, 954, 1824, opacity=.45)
    s += '<g id="core-loop">'
    for i, (head, body) in enumerate([
        ('OBSERVE', 'Study photographs, records, and physical traces.'),
        ('CONNECT', 'Test how objects, surfaces, and light relate.'),
        ('REVEAL', 'Reconstruct the scene and preserve your findings.')]):
        cx = 352 + i * 608
        s += text(cx, 994, head, 36, 'bold', RUST, 'middle')
        s += rule(cx-180, 1006, 360, RUST, 1)
        lines = wrap(body, 525, 21)
        for j, line in enumerate(lines):
            s += text(cx, 1032 + 24*j, line, 21, anchor='middle')
        if i < 2:
            s += vertical(656 + i * 608, 972, 77, .65)
    return s + '</g></svg>'


INSPIRATION = [
    ('01 / EVERYDAY TRACES',
     'Wear marks, displaced furniture and missing equipment suggest habits that outlast the people who used a room. Ordinary objects become clues through their relationships.'),
    ('02 / PARTIAL RECORDS',
     'Photographs capture a moment, but hide what lies outside the frame. Comparing documents with physical traces turns an incomplete record into a testable spatial hypothesis.'),
    ('03 / A WORKING ARCHIVE',
     'The newspaper and case-file language frames information as evidence. A personal studio and retro terminal connect separate investigations through a persistent workspace.'),
]

ARTICLES = [
    dict(key='obra-dinn', x=532, title='RETURN OF THE OBRA DINN', size=34,
         number='REFERENCE 01 / MYSTERY', meta='Lucas Pope · 2018 · Exploration & logical deduction [1]',
         sources=['https://obradinn.com/', 'https://store.steampowered.com/app/653530/Return_of_the_Obra_Dinn/'],
         images=[('obra-dinn-scene.png', 'A frozen scene as spatial evidence.'), ('obra-dinn-book.png', 'Deck plans organize the investigation.')],
         left=[('CORE LOOP', 'Explore the ship, revisit frozen moments, and reconcile identities and fates with the investigation book. Progress comes from making consistent deductions across multiple scenes, rather than following a single highlighted clue.'),
               ('DESIGN READING', 'A scene functions as evidence: position, sightlines and nearby actions can support or contradict a theory. The book externalizes the investigation, helping the player compare fragments and revisit an earlier assumption.')],
         right=[('WHAT WE TAKE', 'Treat photographs as partial records and make physical traces readable from the correct view. Reveal furniture through deductions, then let the final arrangement demonstrate that several clues agree.'),
                ('OUR DEPARTURE', "The target is a room's prior arrangement. Players test a hypothesis by placing objects and calibrating light; the task is spatial reconstruction, rather than identifying a ship's crew.")],
         takeaway='A deduction should explain several clues at once.'),
    dict(key='house-flipper', x=1216, title='HOUSE FLIPPER', size=40,
         number='REFERENCE 02 / BUILDING & RENOVATION', meta='Empyrean · 2018 · Renovation & interior furnishing [2]',
         sources=['https://store.steampowered.com/app/613100/House_Flipper/'],
         images=[('house-flipper-1.jpg', 'A room awaiting renovation.'), ('house-flipper-0.jpg', 'A furnished interior with readable zones.')],
         left=[('CORE LOOP', 'Accept renovation jobs, improve a property with tools, furnish rooms, and reinvest the earnings. Completing a physical task produces a visible change in the room and supports the next job.'),
               ('DESIGN READING', 'Direct interaction makes room-scale decisions tangible. Furniture and renovation tools provide a readable vocabulary of actions, while a task-based structure gives the player a clear reason to alter the environment.')],
         right=[('WHAT WE TAKE', "Use a clear furniture inventory, visible placement feedback, rotation, and undo. Carry job rewards and functional equipment back to the studio, linking a completed investigation to the player's ongoing workspace."),
                ('OUR DEPARTURE', 'The goal is evidential accuracy, rather than a profitable makeover. Placement must satisfy documented spatial relationships, and lighting can be part of the reasoning.')],
         takeaway='Every placement should give useful visual feedback.'),
]


def article(data):
    x, width = data['x'], 656
    s = f'<g id="reference-{data["key"]}">'
    s += text(x, 216, data['number'], 16, 'sansbold', RUST, extra='letter-spacing="1.3"')
    s += text(x, 261, data['title'], data['size'], 'bold')
    s += text(x, 287, data['meta'], 16, 'sans', MUTED)
    s += rule(x, 303, width, opacity=.6)
    for i, (filename, caption) in enumerate(data['images']):
        ix = x + 4 + i * 336
        s += image(REF / filename, ix, 319, 312, 175.5, caption, data['sources'][0])
        s += text(ix, 515, caption, 14, 'italic', MUTED)
    s += rule(x, 535, width, opacity=.65)
    s += vertical(x + 324, 551, 385, .3)
    ends = []
    for col, sections in enumerate((data['left'], data['right'])):
        cx = x + col * 342
        baseline = 566
        for heading, body in sections:
            s += text(cx, baseline, heading, 18, 'sansbold', RUST, extra='letter-spacing=".5"')
            block, end = paragraph(cx, baseline + 29, 308, body, 19, 24)
            s += block
            baseline = end + 30
        ends.append(end)
    assert max(ends) < 950, (data['key'], ends)
    s += rule(x, 952, width, opacity=.5)
    s += text(x, 978, data['takeaway'], 20, 'italic')
    return s + '</g>'


def references():
    s = paper('Scene Calibration — Inspiration & References',
              'Editable all-English newspaper design research page. Left quarter: design inspiration. Right three quarters: Return of the Obra Dinn and House Flipper analyses and official screenshots. The design readings are the project-specific interpretation, not quotations from the developers.')
    s += '<g id="research-masthead">'
    s += text(48, 54, 'SCENE CALIBRATION / DESIGN RESEARCH', 17, 'sansbold', extra='letter-spacing="2"')
    s += text(1872, 54, '02 / INSPIRATION & GAME REFERENCES', 17, 'sans', MUTED, 'end', extra='letter-spacing="1"')
    s += rule(48, 69, 1824) + rule(48, 75, 1824, opacity=.5)
    s += text(48, 141, 'INSPIRATION & REFERENCES', 64, 'bold')
    s += text(48, 176, 'Reading traces, testing relationships, and turning room arrangement into an act of deduction.', 20, 'italic', MUTED)
    s += rule(48, 192, 1824, RUST, 4) + '</g>'
    # 1824 usable pixels: exactly 456px (1/4) left, 1368px (3/4) right.
    s += vertical(504, 210, 785, .8) + vertical(1200, 210, 785, .65)
    s += '<g id="inspiration-quarter">'
    s += text(48, 223, 'INSPIRATION', 21, 'sansbold', RUST, extra='letter-spacing="2"')
    s += text(48, 271, 'WHAT CAN A ROOM', 31, 'bold')
    s += text(48, 307, 'REMEMBER?', 31, 'bold')
    intro = 'Read what remains. Reconstruct the relationships it implies.'
    block, end = paragraph(48, 348, 412, intro, 23, 30, 'italic')
    s += block + rule(48, end + 24, 416, opacity=.65)
    baseline = end + 57
    for heading, body in INSPIRATION:
        s += text(48, baseline, heading, 18, 'sansbold', RUST)
        block, end = paragraph(48, baseline + 31, 412, body, 20, 25)
        s += block
        baseline = end + 35
    assert end < 896, end
    s += rule(48, 903, 416, RUST, 2)
    s += text(48, 934, 'THE DESIGN QUESTION', 17, 'sansbold', RUST, extra='letter-spacing="1"')
    block, end = paragraph(48, 962, 412, 'Can a room be reconstructed from what remains, rather than from a complete picture?', 23, 25, 'italic')
    s += block + '</g>'
    for data in ARTICLES:
        s += article(data)
    s += rule(48, 1020, 1824)
    s += '<g id="source-attribution">'
    s += '<a href="https://obradinn.com/" xlink:href="https://obradinn.com/">'
    s += text(48, 1044, '[1] Return of the Obra Dinn / obradinn.com / Screenshots © 3909 LLC.', 13, 'sans', MUTED) + '</a>'
    s += '<a href="https://store.steampowered.com/app/613100/House_Flipper/" xlink:href="https://store.steampowered.com/app/613100/House_Flipper/">'
    s += text(685, 1044, '[2] House Flipper / Official Steam gallery, app 613100 / Screenshots: Empyrean & publishers.', 13, 'sans', MUTED) + '</a>'
    s += text(1872, 1044, 'DESIGN READINGS = PROJECT ANALYSIS', 12, 'sans', MUTED, 'end')
    return s + '</g></svg>'


def main():
    OUT.mkdir(exist_ok=True)
    (OUT / '01-cover.svg').write_text(cover(), encoding='utf-8')
    (OUT / '02-inspiration-references.svg').write_text(references(), encoding='utf-8')
    house_gallery = json.loads((REF / 'house-flipper-official-screenshots.json').read_text(encoding='utf-8-sig'))
    provenance = {
        'page_size': [1920, 1080], 'aspect_ratio': '16:9', 'text': 'Editable SVG text; Georgia and Arial',
        'image_embedding': 'Self-contained data URIs, unchanged official screenshot pixels',
        'interpretation': 'Core game descriptions are researched; Design Reading / What We Take / Our Departure are project-specific analysis.',
        'inspiration': 'A design premise based on the current project, not a claim about the creator\'s historical influences.',
        'references': [
            {'game': 'Return of the Obra Dinn', 'developer': 'Lucas Pope', 'year': 2018,
             'official_page': 'https://obradinn.com/', 'store_page': ARTICLES[0]['sources'][1],
             'screenshots': [{'file': 'references/obra-dinn-scene.png', 'url': 'https://obradinn.com/img/shots/People-01.png'},
                             {'file': 'references/obra-dinn-book.png', 'url': 'https://obradinn.com/img/shots/Book-03.png'}]},
            {'game': 'House Flipper', 'developer': 'Empyrean', 'year': 2018,
             'official_page': ARTICLES[1]['sources'][0],
             'screenshots': [{'file': f'references/house-flipper-{i}.jpg', 'url': next(s['path_full'] for s in house_gallery if s['id'] == i)} for i in (1, 0)]},
        ]
    }
    (OUT / '02-sources.json').write_text(json.dumps(provenance, indent=2, ensure_ascii=False), encoding='utf-8')
    copy = ['PAGE 01 / COVER', COVER_BODY, '\nPAGE 02 / INSPIRATION & REFERENCES']
    copy.extend(f'{h}\n{b}' for h, b in INSPIRATION)
    for article_data in ARTICLES:
        copy.extend([article_data['title'], article_data['meta']])
        copy.extend(f'{h}\n{b}' for h, b in article_data['left'] + article_data['right'])
    (OUT / 'page-copy.txt').write_text('\n\n'.join(copy), encoding='utf-8')
    print('Created 01-cover.svg and 02-inspiration-references.svg (1920 x 1080).')


if __name__ == '__main__':
    main()
