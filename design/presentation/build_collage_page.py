"""Editable newspaper collage. Photos are embedded; annotations remain vectors.

ImageGen edits are limited to the two background extractions. The chair's
editorial monochrome treatment is a reversible native SVG filter.
"""
from html import escape
import json
from pathlib import Path
from build_pages import OUT, REF, INK, MUTED, RUST, uri, text, paragraph, rule, paper, measure

STEM = '02-inspiration-references-v2-collage'
CUT = REF / 'collage'
BLUE = '#456b75'
GREEN = '#496354'
CREAM = '#faf3e5'


def path(d, color=RUST, width=2.6, arrow=False, dash=None, opacity=1):
    marker = f' marker-end="url(#arrow-{color[1:]})"' if arrow else ''
    dashed = f' stroke-dasharray="{dash}"' if dash else ''
    return (f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{width}" '
            f'stroke-linecap="round" stroke-linejoin="round" opacity="{opacity}"{marker}{dashed}/>')


def body(x, y, width, copy, size=19, leading=25, fill=INK, kind='serif'):
    return paragraph(x, y, width, copy, size, leading, kind, fill)[0]


def tape(x, y, width=76, angle=0, color='#bac5be'):
    return (f'<g transform="rotate({angle} {x+width/2} {y+11})">'
            f'<path d="M{x} {y+2}l8 -2 6 2 10 -1 9 1 7 -2 8 2 8 -1 7 1 8 -2 '
            f'L{x+width} {y+22}l-9 -1 -7 2 -8 -2 -9 1 -7 -1 -8 2 -8 -2 -9 1 -7 -1Z" '
            f'fill="{color}" opacity=".65"/>'
            f'<path d="M{x+4} {y+6}h{width-10}m-{width-12} 9h{width-10}" '
            f'stroke="#f9f5e9" stroke-width=".7" opacity=".45"/></g>')


def ellipse(cx, cy, rx, ry, color=RUST):
    # A second, displaced stroke gives the small imperfection of a pencil mark.
    return (f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="none" '
            f'stroke="{color}" stroke-width="2.5"/>'
            f'<ellipse cx="{cx+1.5}" cy="{cy-1}" rx="{rx+2}" ry="{ry-.5}" '
            f'fill="none" stroke="{color}" stroke-width=".8" opacity=".58"/>')


def badge(x, y, number, color=RUST):
    return (f'<circle cx="{x}" cy="{y}" r="13" fill="{color}"/>'
            + text(x, y+5, str(number), 15, 'sansbold', '#fcf5e6', 'middle'))


def label(x, y, copy, size=17, color=RUST):
    return text(x, y, copy, size, 'sansbold', color)


def annotation_label(x, y, copy):
    width = measure(copy, 14, 'sansbold') + 12
    return (f'<rect x="{x-6}" y="{y-16}" width="{width}" height="22" fill="{CREAM}" opacity=".96"/>'
            + text(x, y, copy, 14, 'sansbold', RUST))


def link(url, contents):
    return f'<a href="{escape(url, quote=True)}" xlink:href="{escape(url, quote=True)}">{contents}</a>'


def photo(file, x, y, width, angle, caption, identifier, source, overlays='', caption_top=False):
    height = width * 9 / 16
    cx, cy = x+width/2, y+height/2
    mount_y = y-31 if caption_top else y-10
    mount_h = height+41 if caption_top else height+38
    caption_y = y-11 if caption_top else y+height+19
    tape_x = x+width*.78 if caption_top else x+width*.14
    tape_y = y-40 if caption_top else y-18
    s = (f'<g id="{identifier}" transform="rotate({angle} {cx} {cy})">'
         f'<rect x="{x-10}" y="{mount_y}" width="{width+20}" height="{mount_h}" '
         f'fill="{CREAM}" stroke="#a59783" stroke-width=".9" filter="url(#mount-shadow)"/>'
         f'<image x="{x}" y="{y}" width="{width}" height="{height}" '
         f'preserveAspectRatio="xMidYMid meet" href="{uri(file)}" xlink:href="{uri(file)}"/>'
         f'{overlays}'
         + text(x+width/2, caption_y, caption, 14, 'sans', MUTED, 'middle')
         + tape(tape_x, tape_y, 76, 5)
         + '</g>')
    return link(source, s)


def cutout(file, x, y, width, height, angle, identifier, toned=False):
    f = ' filter="url(#newsprint-tone)"' if toned else ''
    return (f'<g id="{identifier}" transform="rotate({angle} {x+width/2} {y+height/2})">'
            f'<image x="{x}" y="{y}" width="{width}" height="{height}" '
            f'preserveAspectRatio="xMidYMid meet" href="{uri(file)}" xlink:href="{uri(file)}"{f}/></g>')


def build():
    s = paper('Inspiration & References — Collage Study',
              'Lightly aged 16:9 newspaper. The left quarter collages transparent chair and camera cutouts. '
              'The right three quarters analyze Return of the Obra Dinn and House Flipper through six '
              'official screenshots, numbered callouts and editable mechanism arrows. All type is English.')
    extra_defs = ('<filter id="mount-shadow" x="-.2" y="-.2" width="1.5" height="1.5">'
                  '<feDropShadow dx="2" dy="3" stdDeviation="2.2" flood-color="#5b4c3b" flood-opacity=".18"/></filter>'
                  '<filter id="newsprint-tone" color-interpolation-filters="sRGB">'
                  '<feColorMatrix type="matrix" values=".31 .61 .08 0 .03  .29 .57 .07 0 .015  .25 .50 .06 0 0  0 0 0 1 0"/></filter>')
    for color in (RUST, BLUE, GREEN):
        extra_defs += (f'<marker id="arrow-{color[1:]}" viewBox="0 0 14 12" refX="11" refY="6" '
                       f'markerWidth="9" markerHeight="9" orient="auto-start-reverse" markerUnits="userSpaceOnUse">'
                       f'<path d="M1 1L11 6 1 11" fill="none" stroke="{color}" stroke-width="2" '
                       'stroke-linecap="round" stroke-linejoin="round"/></marker>')
    s = s.replace('</defs>', extra_defs+'</defs>')
    s += '<g id="masthead">'
    s += text(48, 49, 'SCENE CALIBRATION / DESIGN DOSSIER', 17, 'sansbold', MUTED, extra='letter-spacing="1.8"')
    s += text(1870, 49, 'NO. 02  /  REFERENCE STUDY', 17, 'sansbold', MUTED, 'end')
    s += text(48, 119, 'INSPIRATION & REFERENCES', 72, 'bold')
    s += text(50, 156, 'Read the traces. Test the relationships. Build a scene that makes the evidence agree.', 23, 'italic')
    s += rule(48, 177, 1824, INK, 2.2) + rule(48, 182, 1824, INK, .6)
    s += '</g>'
    # A quiet fold preserves the 1:3 split without enclosing the collage in a grid.
    s += path('M516 202V1008', INK, .85, dash='2 6', opacity=.32)

    s += '<g id="inspiration-left-quarter">'
    s += label(50, 214, '01 / FOUND IN EVERYDAY LIFE', 17)
    s += text(50, 259, 'What can a room', 35, 'bold')
    s += text(50, 300, 'remember?', 35, 'bold')
    # A ghost plan and scuff marks are explanatory vector sketches, not game images.
    s += '<g id="chair-evidence-sketch" transform="rotate(-9 153 566)" opacity=".68">'
    s += '<path d="M63 542l139 -11 28 59 -141 15Z" fill="#e7e5d5" stroke="#899487" stroke-width="1.1"/>'
    s += path('M78 555l106 -8m-105 14 110 -8m-104 29 116 -9', BLUE, .8, opacity=.35)
    s += path('M138 554l43 -4m-42 10 47 -5m-43 10 35 -3', RUST, 1.5, opacity=.7)
    s += '<path d="M72 536l12 -1m-8 -6 -1 12M214 596l13 -1m-6 -5 -1 11" stroke="#899487" stroke-width="1"/>'
    s += '</g>'
    s += cutout(CUT/'wooden-chair-cutout.png', 70, 317, 180, 313, -9, 'wooden-chair-cutout', True)
    s += label(277, 349, 'PHYSICAL TRACES', 18)
    s += body(277, 380, 218,
              'Furniture, wear marks and gaps preserve a room\'s habits. An ordinary object becomes evidence through what touches it.', 19, 26)
    s += ellipse(147, 604, 39, 14)
    s += path('M282 560C260 571 245 602 190 604', arrow=True)
    s += text(279, 570, 'A position has a history.', 19, 'italic', RUST)

    # Contact-print fragments beneath the cutout make the partial-frame idea visible.
    s += '<g id="partial-records-contact-print" transform="rotate(-8 162 721)">'
    s += '<rect x="57" y="649" width="221" height="151" fill="#faf5e9" stroke="#b3a68f" stroke-width=".9"/>'
    s += '<rect x="66" y="657" width="202" height="114" fill="#bbc1b1"/>'
    s += path('M70 735h192M88 671v91m78 -97v97m77 -97v97', '#667567', 1.1, opacity=.5)
    s += '<path d="M90 727v-39h57v39m-48 -23h41m-48 29v21m57 -21v21" fill="none" stroke="#677565" stroke-width="2"/>'
    s += '<path d="M233 658v111" stroke="#faf5e9" stroke-width="7" stroke-dasharray="4 4"/>'
    s += text(71, 790, 'PRESENCE ≠ THE WHOLE STORY', 11, 'sansbold', MUTED)
    s += tape(71, 640, 76, 4, '#cbbd9c') + '</g>'
    s += cutout(CUT/'camera-cutout.png', 56, 662, 226, 174, 7, 'vintage-camera-cutout')
    s += label(296, 662, 'PARTIAL RECORDS', 17)
    s += body(296, 695, 197,
              'A photo proves presence, but its edges hide context. Compare the frame with traces in the room.', 19, 25)
    s += path('M292 827C274 852 238 848 217 825', BLUE, 2.4, True)
    s += text(61, 865, 'WHAT IS OUTSIDE THE FRAME?', 15, 'sansbold', BLUE)
    s += rule(52, 882, 440, INK, .6, .45)
    s += label(55, 909, 'A WORKING ARCHIVE', 17)
    s += body(55, 938, 433,
              'Clippings, case files and a retro terminal turn separate clues into a persistent workspace.', 18, 24)
    s += text(55, 1001, 'Rebuild relationships, not just a room.', 19, 'italic', RUST)
    s += '</g>'

    s += '<g id="obra-dinn-analysis">'
    s += text(550, 221, '02', 24, 'italic', RUST)
    s += text(597, 221, 'RETURN OF THE OBRA DINN', 38, 'bold')
    s += text(597, 248, 'Lucas Pope · 2018 · Frozen scenes + investigation records [1]', 16, 'sans', MUTED)
    s += label(1870, 221, 'READ THE SCENE', 17).replace('text-anchor="start"', 'text-anchor="end"')
    a_marks = ellipse(803, 402, 42, 38) + badge(744, 439, 1)
    s += photo(REF/'obra-dinn-scene.png', 558, 284, 443, -2.2,
               '1 / OBSERVE — actions and positions', 'obra-frozen-scene', 'https://obradinn.com/', a_marks)
    b_marks = ellipse(1144, 344, 27, 32) + badge(1179, 310, 2)
    s += photo(REF/'obra-dinn-book-04.png', 1041, 285, 334, 3,
               '2 / RECORD — compare identities', 'obra-portraits', 'https://obradinn.com/', b_marks, True)
    c_marks = ellipse(1202, 442, 28, 23) + badge(1168, 442, 3)
    s += photo(REF/'obra-dinn-book.png', 1140, 389, 310, -3.6,
               '3 / CROSS-CHECK — place in context', 'obra-deck-plan', 'https://obradinn.com/', c_marks)
    s += '<g id="obra-mechanism-arrows">'
    s += path('M848 380C925 331 977 337 1049 333', arrow=True)
    s += annotation_label(931, 302, 'COMPARE')
    s += path('M1023 408C1077 410 1123 411 1167 431', arrow=True, dash='5 4')
    s += annotation_label(1005, 421, 'CHECK')
    s += '</g>'
    s += label(1521, 291, 'WHY IT WORKS', 17)
    s += body(1521, 323, 346,
              'People, sightlines and nearby actions carry information. The book helps the player compare fragments across scenes.', 19, 25)
    s += path('M1521 441h125', INK, .8, opacity=.5)
    s += label(1521, 473, 'IN SCENE CALIBRATION', 17, GREEN)
    s += body(1521, 504, 346,
              'Use partial photos and view-dependent traces. A valid furniture layout must reconcile several clues.', 19, 25)
    # A native-vector translation of the reference into this project's core loop.
    s += '<g id="deduction-transfer">'
    s += label(562, 591, 'WHAT WE TAKE', 15, GREEN)
    s += text(562, 622, 'PHOTO + TRACE', 18, 'sansbold', GREEN)
    s += path('M729 616C765 612 787 613 814 616', GREEN, 2.6, True)
    s += text(835, 622, 'SPATIAL HYPOTHESIS', 18, 'sansbold', GREEN)
    s += path('M1050 616C1067 618 1079 620 1094 620', GREEN, 2.6, True)
    s += text(562, 647, 'The restored room becomes a test of the deduction.', 17, 'italic', MUTED)
    # Small room diagram: furniture is a hypothesis, not an arbitrary decoration.
    s += '<g id="room-hypothesis-diagram" transform="rotate(-3 1267 619)">'
    s += '<path d="M1118 595h137v54h-49m-20 0h-68Z" fill="#dfe4d7" fill-opacity=".5" stroke="#496354" stroke-width="1.5"/>'
    s += '<rect x="1141" y="607" width="43" height="24" fill="#aab9a7" stroke="#496354" stroke-width="1.2"/>'
    s += '<rect x="1211" y="603" width="24" height="34" fill="none" stroke="#496354" stroke-width="1.2" stroke-dasharray="3 3"/>'
    s += path('M1192 618h13', GREEN, 1.8, True)
    s += '</g>'
    s += text(1290, 616, 'RECONSTRUCT + VERIFY', 18, 'sansbold', GREEN)
    s += '</g></g>'

    s += '<g id="house-flipper-analysis">'
    s += rule(551, 668, 1320, INK, .8, .6)
    s += text(550, 706, '03', 24, 'italic', RUST)
    s += text(597, 706, 'HOUSE FLIPPER', 38, 'bold')
    s += text(597, 730, 'Empyrean · 2018 · Renovation, furnishing and a job economy [2]', 16, 'sans', MUTED)
    s += text(1870, 706, 'MAKE CHANGE TANGIBLE', 17, 'sansbold', RUST, 'end')
    dirty_marks = ellipse(724, 909, 37, 25) + badge(680, 910, 1)
    s += photo(REF/'house-flipper-1.jpg', 559, 771, 362, 1.5,
               '1 / INSPECT — identify the work', 'house-renovation-condition',
               'https://store.steampowered.com/app/613100/House_Flipper/', dirty_marks)
    clean_marks = ellipse(1191, 895, 25, 32) + badge(1223, 872, 2)
    s += photo(REF/'house-flipper-0.jpg', 957, 765, 310, -3.2,
               '2 / FURNISH — objects define use', 'house-kitchen-layout',
               'https://store.steampowered.com/app/613100/House_Flipper/', clean_marks, True)
    bedroom_marks = ellipse(1368, 931, 40, 20) + badge(1315, 942, 3)
    s += photo(REF/'house-flipper-3.jpg', 1223, 833, 264, 2.5,
               '3 / FEEDBACK — a readable result', 'house-bedroom-result',
               'https://store.steampowered.com/app/613100/House_Flipper/', bedroom_marks)
    s += '<g id="building-mechanism-arrows">'
    s += path('M762 916C836 850 887 824 958 819', arrow=True)
    s += annotation_label(870, 805, 'ACT')
    s += path('M1183 932C1191 980 1278 985 1328 955', BLUE, 2.5, True)
    s += '</g>'
    s += label(1521, 778, 'WHY IT WORKS', 17)
    s += body(1521, 809, 346,
              'Tools and furniture make progress visible. Jobs pay for the next task and a growing workspace.', 19, 25)
    s += path('M1521 895h125', INK, .8, opacity=.5)
    s += label(1521, 925, 'IN SCENE CALIBRATION', 17, GREEN)
    s += body(1521, 956, 346,
              'Place, rotate and undo; test against evidence. Carry rewards and equipment back to the studio.', 19, 25)
    s += '</g>'

    s += '<g id="source-credits">'
    s += rule(48, 1021, 1824, INK, .8)
    game_credit = ('Official screenshots: [1] obradinn.com / © 3909 LLC.  [2] House Flipper Steam gallery / © Empyrean. '
                   'Different rooms shown; not a matched before/after. Red annotations: design analysis.')
    s += text(49, 1040, game_credit, 13, 'sans', MUTED)
    x = 49
    for url, copy in [
        ('https://commons.wikimedia.org/wiki/File:Wooden_Chair.jpg', 'Cutouts: Wooden Chair — epSos.de'),
        ('https://creativecommons.org/licenses/by/2.0/', '(CC BY 2.0);'),
        ('https://commons.wikimedia.org/wiki/File:Agfa_Isola_II.jpg', 'Agfa Isola II — Alfred'),
        ('https://creativecommons.org/licenses/by-sa/2.0/', '(CC BY-SA 2.0).')]:
        s += link(url, text(x, 1058, copy, 12, 'sans', MUTED))
        x += measure(copy, 12, 'sans') + 6
    s += text(x+8, 1058, 'Backgrounds removed; chair toned. Source and license links embedded. Mechanism annotations are design interpretations.', 12, 'sans', MUTED)
    s += text(1869, 1058, '02', 15, 'sansbold', MUTED, 'end')
    s += '</g></svg>'
    return s


def sources():
    prior = json.loads((OUT/'02-sources.json').read_text(encoding='utf-8'))
    prior.update({
        'edition': 'Collage v2',
        'page': STEM+'.svg',
        'composition': 'Left one quarter: inspiration collage. Right three quarters: two visually annotated game studies.',
        'editable': 'English text, illustration sketches, photograph mounts, tape, arrows and circles are native SVG; source images are embedded.',
        'screenshot_treatment': 'Full 16:9 screenshots scaled and gently rotated, not recolored or retouched. Vector annotations are visibly separate.',
        'caution_for_interpretation': 'The six screenshots illustrate different scenes/rooms. Arrows are analytical connections, not a claim of matching before/after or exact person identity.',
        'cutout_method': 'Built-in ImageGen, edit / background-extraction. Alpha confirmed. Chair tonal filter is reversible SVG code.',
    })
    prior['references'][0]['screenshots'].insert(1, {
        'file': 'references/obra-dinn-book-04.png',
        'url': 'https://obradinn.com/img/shots/Book-04.png'})
    flipper = json.loads((REF/'house-flipper-official-screenshots.json').read_text(encoding='utf-8'))
    shots = flipper if isinstance(flipper, list) else flipper.get('screenshots', [])
    shot = next((i for i in shots if i.get('id') == 3), None)
    url = (shot or {}).get('path_full', 'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/613100/ss_d60e717912e65c85243393552c96b96efe949d96.1920x1080.jpg')
    prior['references'][1]['screenshots'].append({'file': 'references/house-flipper-3.jpg', 'url': url})
    prior['inspiration_assets'] = [
        {'title': 'Wooden Chair', 'author': 'epSos.de',
         'source_page': 'https://commons.wikimedia.org/wiki/File:Wooden_Chair.jpg',
         'original_source': 'https://www.flickr.com/photos/36495803@N05/6018530839/',
         'source_image': 'references/collage/wooden-chair-source.jpg',
         'cutout': 'references/collage/wooden-chair-cutout.png',
         'license': 'CC BY 2.0', 'license_url': 'https://creativecommons.org/licenses/by/2.0/',
         'changes': 'Background removed using ImageGen; reversible monochrome SVG filter in composition.'},
        {'title': 'Agfa Isola II', 'author': 'Alfred',
         'source_page': 'https://commons.wikimedia.org/wiki/File:Agfa_Isola_II.jpg',
         'original_source': 'https://www.flickr.com/photos/alf_sigaro/292259201/',
         'source_image': 'references/collage/camera-source.jpg',
         'cutout': 'references/collage/camera-cutout.png',
         'license': 'CC BY-SA 2.0', 'license_url': 'https://creativecommons.org/licenses/by-sa/2.0/',
         'derivative_license': 'CC BY-SA 2.0 applies to the isolated camera PNG.',
         'changes': 'Background removed using ImageGen; no compositional recoloring.'}]
    return prior


if __name__ == '__main__':
    svg = build()
    (OUT/(STEM+'.svg')).write_text(svg, encoding='utf-8')
    (OUT/(STEM+'-sources.json')).write_text(json.dumps(sources(), indent=2, ensure_ascii=False), encoding='utf-8')
    print(f'Built {STEM}.svg')
