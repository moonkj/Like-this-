"""
Like This 앱 아이콘 생성기
스플래시 스크린과 동일한 디자인:
- OLED Black (#000000) 배경
- Silver (#C0C0C0) 원형 테두리
- camera_alt_outlined 아이콘 (silver)
"""

from PIL import Image, ImageDraw
import os

# 4x 슈퍼샘플링으로 안티앨리어싱
SUPER = 4
OUT_SIZE = 1024
DRAW_SIZE = OUT_SIZE * SUPER

img = Image.new("RGBA", (DRAW_SIZE, DRAW_SIZE), (0, 0, 0, 255))
draw = ImageDraw.Draw(img)

SILVER = (192, 192, 192, 255)
cx = cy = DRAW_SIZE // 2

# ── 원형 테두리 ──────────────────────────────────────────────
circle_r = DRAW_SIZE * 0.40
border_w = max(4, int(DRAW_SIZE * 0.021))

draw.ellipse(
    [cx - circle_r, cy - circle_r, cx + circle_r, cy + circle_r],
    outline=SILVER,
    width=border_w,
)

# ── 카메라 아이콘 ─────────────────────────────────────────────
# 24x24 뷰박스 기준, 스플래시와 동일 비율 (32/72)
icon_span = DRAW_SIZE * 0.40
scale = icon_span / 24.0
# 시각 무게중심: 아이콘 기준점 살짝 위로
ox = cx - icon_span / 2
oy = cy - icon_span / 2 - scale * 0.3

stroke = max(2, int(scale * 0.95))
corner_r = int(scale * 2.0)


def p(x, y):
    return (ox + x * scale, oy + y * scale)


# 카메라 외형 = 바디 + 뷰파인더 범프 하나의 폴리곤
# Material camera_alt path 기반 (24x24 grid)
# 바디: x2~22, y7~19, 범프: (9,3)~(15,3) 사다리꼴
camera_outline = [
    p(9, 3),       # 범프 상단 좌
    p(7.17, 5),    # 범프 하단 좌 (사선)
    p(2, 5),       # 좌상단 → 라운드 코너로 이어짐
    p(2, 7),
    p(2, 19),      # 좌하단
    p(22, 19),     # 우하단
    p(22, 7),
    p(22, 5),      # 우상단 → 라운드 코너
    p(16.83, 5),   # 범프 하단 우 (사선)
    p(15, 3),      # 범프 상단 우
    p(9, 3),       # 닫기
]
draw.line(camera_outline, fill=SILVER, width=stroke)

# 바디 상단 수평선 (범프 양쪽): x2→7.17 and x16.83→22 at y=7
draw.line([p(2, 7), p(7.17, 7)], fill=SILVER, width=stroke)
draw.line([p(16.83, 7), p(22, 7)], fill=SILVER, width=stroke)

# 범프 좌우 수직 연결선 (y5→y7)
draw.line([p(7.17, 5), p(7.17, 7)], fill=SILVER, width=stroke)
draw.line([p(16.83, 5), p(16.83, 7)], fill=SILVER, width=stroke)

# 렌즈 링: 외부 r=5, 내부 r=3.2  center=(12,13)
lx, ly = p(12, 13)
for r_val in [5.0, 3.2]:
    r = scale * r_val
    draw.ellipse([lx - r, ly - r, lx + r, ly + r], outline=SILVER, width=stroke)

# ── 다운샘플링 (LANCZOS) ─────────────────────────────────────
out = img.resize((OUT_SIZE, OUT_SIZE), Image.LANCZOS)

out_path = os.path.normpath(
    os.path.join(os.path.dirname(__file__), "../assets/images/app_icon.png")
)
out.save(out_path)
print(f"Saved: {out_path} ({OUT_SIZE}x{OUT_SIZE})")
