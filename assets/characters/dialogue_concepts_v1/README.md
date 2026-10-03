# 对话角色设定 · 第一版

使用内置 imagegen 生成。参考图仅用于手绘线条、色彩与服装细节风格。以下人物年龄、性别及造型为本次初稿设计，不代表已确认的剧情设定。

- 主角：约 28 岁女性现场调查员，栗色短发、锈红夹克、灰绿工作服、记录本和测量工具，神情专注；朝右，可放对话框左侧。
- 警察：约 42 岁男性警官，深色夹灰短发、蓝灰制服、简化警徽与无线电，表情沉稳；朝左，可放对话框右侧。

两张图均为 1024 × 1536 白底 PNG 原画，不含透明通道。需要透明叠加时仍需抠图；尚未绑定对话界面。主角最初生成的棋盘格背景版本已弃用。

## 原始提示词

### 主角

Use case: stylized-concept. Generate ONE original female protagonist dialogue portrait for a grounded mystery reconstruction detective game. Reference image is STYLE ONLY: preserve its expressive thin irregular dark-brown ink contours, elegant elongated adult proportions, muted rust-red and grey sage/teal palette, flat gouache-like patches, economical angular cel shadows, lightly distressed fabric and carefully drawn practical buckles/seams. Do NOT reproduce the reference person or gas mask/scifi equipment. Subject: a 28-year-old female civilian scene investigator, thoughtful observant expression, tired intelligent eyes, short uneven dark chestnut bob with one tucked side, rust-brown oversized utility jacket, muted sage vest over ivory high-neck shirt, small leather notebook tucked under one arm, a modest measuring-tool pouch and leather shoulder strap, worn practical trousers. Hands relaxed and anatomically natural. Face fully visible; approachable, reserved, resourceful. Composition: single isolated character, head to just below knees, both elbows and hands fully inside frame with margin, centered portrait canvas approximately 2:3, three-quarter body turning gently toward viewer's right, eyes toward dialogue partner on right. Face large enough for visual novel dialogue UI. Transparent RGBA background, absolutely no scenery, no ground shadow, no captions, no labels, no palette swatches, no multiple views, no border, no watermark, no white background or drawn checkerboard. Restrained hand-drawn narrative game concept illustration, not photoreal, not glossy 3D, not generic shiny anime. This is a production dialogue character cutout, not a design sheet.

### 主角背景修正

Edit the supplied female investigator portrait. Preserve the character EXACTLY: same face, hair, rust utility jacket, sage vest and trousers, notebook, hands, pose, proportions, framing, colors and fine ink illustration details. Change ONLY the checkerboard background to clean uniform solid white (#FFFFFF). Remove every visible grey checker square around the character and in gaps between hair, straps and arms. No checkerboard, no grey backdrop, no ground shadow. Do not redesign or add anything. Output a clean white-background character portrait.

### 警察

Create ONE original middle-aged male police officer dialogue portrait, a matching partner character for a grounded mystery investigation game. First reference supplies the art style: irregular fine dark-brown hand-drawn ink, muted gouache flats, angular cel shadows, elongated but believable adult anatomy, intricate worn garment seams and useful pockets. Second reference supplies the matching visual language for his female investigator partner; do not include her in this image. The officer is 42, short dark hair with grey temples, clean-shaven square face, slightly heavy eyebrows, calm watchful eyes, restrained concerned expression. Worn charcoal blue-grey uniform jacket with muted sage shirt, simple shoulder epaulettes, small generic brass shield badge with no lettering, brown belt with radio pouch, a small investigation notebook held loosely in one hand. Grounded contemporary fictional police officer, no weapons, no military armor, no gas mask, no sci-fi hardware. Face fully visible. Single character centered in portrait 2:3 canvas, framed head through knees, arms and hands fully inside borders. Three-quarter body facing gently LEFT with gaze to the left, suitable as the right-side speaker opposite the protagonist. Consistent scale and fine expressive linework with the female reference; flat artistic illustration, not photographic or glossy anime. Plain solid WHITE background, no checkerboard, no scenery, no ground shadow, no text labels or watermark, no extra views.

