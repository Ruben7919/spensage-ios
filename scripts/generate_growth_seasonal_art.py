#!/usr/bin/env python3

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
BRAND_ROOT = ROOT / "SpendSage" / "Resources" / "Brand" / "v2"
CHAR_ROOT = BRAND_ROOT / "characters"
GUIDE_ROOT = BRAND_ROOT / "guides"
BADGE_ROOT = BRAND_ROOT / "badges"

GUIDE_SIZE = (1536, 1024)
BADGE_SIZE = 512


def lerp(a: int, b: int, t: float) -> int:
    return int(round(a + (b - a) * t))


def gradient_background(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    width, height = size
    canvas = Image.new("RGBA", size)
    draw = ImageDraw.Draw(canvas)
    for y in range(height):
        t = y / max(height - 1, 1)
        color = tuple(lerp(top[i], bottom[i], t) for i in range(3)) + (255,)
        draw.line((0, y, width, y), fill=color)
    return canvas


def add_glow(canvas: Image.Image, center: tuple[int, int], radius: int, color: tuple[int, int, int], alpha: int) -> None:
    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    x, y = center
    draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=color + (alpha,))
    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=max(radius // 2, 1)))
    canvas.alpha_composite(overlay)


def rounded_panel(
    canvas: Image.Image,
    box: tuple[int, int, int, int],
    fill: tuple[int, int, int, int],
    outline: tuple[int, int, int, int],
    radius: int,
    shadow_alpha: int = 48,
) -> None:
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sx0, sy0, sx1, sy1 = box
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle((sx0 + 12, sy0 + 18, sx1 + 12, sy1 + 18), radius=radius, fill=(18, 31, 36, shadow_alpha))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=24))
    canvas.alpha_composite(shadow)

    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=3)
    canvas.alpha_composite(overlay)


def add_sparkles(canvas: Image.Image, points: list[tuple[int, int]], color: tuple[int, int, int]) -> None:
    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    for x, y in points:
        draw.line((x - 14, y, x + 14, y), fill=color + (185,), width=4)
        draw.line((x, y - 14, x, y + 14), fill=color + (185,), width=4)
        draw.ellipse((x - 4, y - 4, x + 4, y + 4), fill=(255, 255, 255, 220))
    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=1))
    canvas.alpha_composite(overlay)


def paste_character(canvas: Image.Image, filename: str, box: tuple[int, int, int, int], shadow_alpha: int = 80) -> None:
    sprite = Image.open(CHAR_ROOT / filename).convert("RGBA")
    x0, y0, x1, y1 = box
    target_w = x1 - x0
    target_h = y1 - y0
    sprite.thumbnail((target_w, target_h), Image.LANCZOS)

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    center_x = x0 + target_w // 2
    shadow_draw.ellipse((center_x - 180, y1 - 44, center_x + 180, y1 + 28), fill=(18, 28, 33, shadow_alpha))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=24))
    canvas.alpha_composite(shadow)

    dest_x = x0 + (target_w - sprite.width) // 2
    dest_y = y0 + (target_h - sprite.height)
    canvas.alpha_composite(sprite, (dest_x, dest_y))


def draw_mission_row(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], accent: tuple[int, int, int], warm: bool = False) -> None:
    x0, y0, x1, y1 = box
    fill = (253, 251, 247, 245) if warm else (247, 251, 251, 245)
    draw.rounded_rectangle(box, radius=26, fill=fill, outline=(208, 225, 223, 255), width=2)
    draw.rounded_rectangle((x0 + 18, y0 + 16, x0 + 86, y1 - 16), radius=20, fill=accent + (255,))
    draw.ellipse((x0 + 38, y0 + 36, x0 + 66, y0 + 64), fill=(255, 248, 228, 255))
    draw.rounded_rectangle((x0 + 112, y0 + 22, x1 - 120, y0 + 36), radius=6, fill=(225, 236, 236, 255))
    draw.rounded_rectangle((x0 + 112, y0 + 50, x1 - 170, y0 + 64), radius=6, fill=(239, 244, 244, 255))
    draw.rounded_rectangle((x0 + 112, y1 - 42, x1 - 118, y1 - 24), radius=9, fill=(229, 241, 239, 255))
    draw.rounded_rectangle((x0 + 112, y1 - 42, x0 + int((x1 - x0) * 0.74), y1 - 24), radius=9, fill=accent + (255,))
    draw.rounded_rectangle((x1 - 96, y0 + 20, x1 - 28, y0 + 54), radius=17, fill=(255, 246, 227, 255))


def draw_progress_board(
    canvas: Image.Image,
    box: tuple[int, int, int, int],
    accent: tuple[int, int, int],
    secondary: tuple[int, int, int],
    warm: bool = False,
) -> None:
    rounded_panel(canvas, box, (249, 252, 252, 238), (205, 225, 223, 255), radius=48)
    draw = ImageDraw.Draw(canvas)
    x0, y0, x1, y1 = box

    draw.rounded_rectangle((x0 + 48, y0 + 42, x1 - 48, y0 + 130), radius=32, fill=(255, 248, 235, 255), outline=(226, 226, 214, 255), width=2)
    draw.rounded_rectangle((x0 + 92, y0 + 70, x1 - 150, y0 + 102), radius=16, fill=(225, 240, 238, 255))
    draw.rounded_rectangle((x0 + 92, y0 + 70, x0 + int((x1 - x0) * 0.72), y0 + 102), radius=16, fill=accent + (255,))
    draw.ellipse((x0 + 52, y0 + 56, x0 + 116, y0 + 120), fill=secondary + (255,))
    draw.ellipse((x1 - 132, y0 + 52, x1 - 56, y0 + 128), fill=(255, 221, 140, 255))

    row_specs = [
        (y0 + 186, accent, False),
        (y0 + 318, secondary, True),
        (y0 + 450, accent, False),
    ]
    for top, row_accent, row_warm in row_specs:
        draw_mission_row(draw, (x0 + 46, top, x1 - 46, top + 104), row_accent, warm=row_warm)


def draw_pumpkin(draw: ImageDraw.ImageDraw, center: tuple[int, int], radius: int) -> None:
    x, y = center
    fill = (245, 139, 59, 255)
    stroke = (152, 78, 28, 255)
    for offset in (-radius // 2, 0, radius // 2):
        draw.ellipse((x - radius + offset, y - radius, x + radius + offset, y + radius), fill=fill, outline=stroke, width=4)
    draw.rectangle((x - 8, y - radius - 18, x + 8, y - radius + 4), fill=(79, 112, 52, 255))
    draw.line((x + 4, y - radius - 6, x + 26, y - radius - 20), fill=(79, 112, 52, 255), width=5)


def draw_gift(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], fill: tuple[int, int, int]) -> None:
    x0, y0, x1, y1 = box
    draw.rounded_rectangle(box, radius=16, fill=fill + (255,), outline=(255, 247, 233, 255), width=3)
    center_x = (x0 + x1) // 2
    center_y = (y0 + y1) // 2
    draw.rectangle((center_x - 10, y0, center_x + 10, y1), fill=(255, 242, 225, 255))
    draw.rectangle((x0, center_y - 10, x1, center_y + 10), fill=(255, 242, 225, 255))
    draw.ellipse((center_x - 34, y0 - 18, center_x, y0 + 18), outline=(255, 242, 225, 255), width=6)
    draw.ellipse((center_x, y0 - 18, center_x + 34, y0 + 18), outline=(255, 242, 225, 255), width=6)


def draw_snowflake(draw: ImageDraw.ImageDraw, center: tuple[int, int], radius: int, fill: tuple[int, int, int]) -> None:
    x, y = center
    for angle in range(0, 180, 45):
        dx = math.cos(math.radians(angle)) * radius
        dy = math.sin(math.radians(angle)) * radius
        draw.line((x - dx, y - dy, x + dx, y + dy), fill=fill + (220,), width=4)
    draw.ellipse((x - 5, y - 5, x + 5, y + 5), fill=(255, 255, 255, 220))


def draw_firework(draw: ImageDraw.ImageDraw, center: tuple[int, int], radius: int, fill: tuple[int, int, int]) -> None:
    x, y = center
    for angle in range(0, 360, 30):
        dx = math.cos(math.radians(angle)) * radius
        dy = math.sin(math.radians(angle)) * radius
        draw.line((x, y, x + dx, y + dy), fill=fill + (220,), width=5)
    draw.ellipse((x - 9, y - 9, x + 9, y + 9), fill=(255, 250, 234, 255))


def create_dashboard_scene(theme: str) -> Image.Image:
    if theme == "halloween":
        canvas = gradient_background(GUIDE_SIZE, (248, 237, 224), (57, 63, 78))
        add_glow(canvas, (1180, 260), 220, (255, 165, 95), 124)
        add_glow(canvas, (300, 250), 260, (255, 213, 124), 92)
        draw_progress_board(canvas, (102, 138, 880, 888), (123, 205, 156), (248, 169, 72), warm=True)
        draw = ImageDraw.Draw(canvas)
        draw_pumpkin(draw, (240, 842), 38)
        draw_pumpkin(draw, (792, 834), 34)
        draw_firework(draw, (1012, 188), 28, (255, 198, 114))
        paste_character(canvas, "manchas_warning_v2.png", (918, 174, 1458, 900))
        add_sparkles(canvas, [(368, 168), (734, 150), (1250, 238), (1332, 712)], (255, 206, 123))
        return canvas

    if theme == "holiday":
        canvas = gradient_background(GUIDE_SIZE, (228, 244, 242), (255, 244, 236))
        add_glow(canvas, (1186, 252), 240, (255, 218, 170), 124)
        add_glow(canvas, (312, 256), 250, (174, 233, 224), 118)
        draw_progress_board(canvas, (102, 138, 880, 888), (102, 184, 168), (225, 92, 92))
        draw = ImageDraw.Draw(canvas)
        draw_gift(draw, (210, 796, 306, 892), (221, 92, 92))
        draw_gift(draw, (722, 802, 816, 890), (100, 179, 150))
        for point in [(258, 188), (364, 208), (720, 174), (808, 214), (1058, 188), (1346, 658)]:
            draw_snowflake(draw, point, 18, (255, 255, 255))
        paste_character(canvas, "manchas_proud_v2.png", (916, 178, 1452, 904))
        add_sparkles(canvas, [(430, 170), (742, 152), (1256, 214), (1338, 716)], (255, 210, 128))
        return canvas

    canvas = gradient_background(GUIDE_SIZE, (232, 245, 244), (255, 242, 231))
    add_glow(canvas, (1178, 252), 240, (255, 223, 168), 120)
    add_glow(canvas, (314, 254), 260, (170, 233, 225), 118)
    draw_progress_board(canvas, (102, 138, 880, 888), (120, 205, 194), (255, 196, 92))
    draw = ImageDraw.Draw(canvas)
    draw_gift(draw, (208, 808, 296, 886), (120, 205, 194))
    draw.rounded_rectangle((728, 808, 818, 880), radius=18, fill=(255, 227, 184, 255), outline=(233, 176, 88, 255), width=3)
    draw.ellipse((746, 820, 800, 874), fill=(255, 248, 232, 255))
    paste_character(canvas, "manchas_proud_v2.png", (916, 176, 1452, 904))
    add_sparkles(canvas, [(372, 170), (706, 150), (1238, 204), (1334, 718)], (255, 206, 118))
    return canvas


def create_team_scene(theme: str, loading: bool) -> Image.Image:
    if theme == "halloween":
        canvas = gradient_background(GUIDE_SIZE, (245, 235, 223), (59, 65, 79))
        add_glow(canvas, (270, 230), 240, (255, 195, 120), 110)
        add_glow(canvas, (1260, 238), 260, (255, 154, 96), 108)
        panel_fill = (250, 250, 248, 224)
        accent_left = (88, 177, 191)
        accent_center = (248, 168, 72)
        accent_right = (121, 204, 170)
        left_char = "tikki_shocked_v2.png" if loading else "tikki_proud_v2.png"
        center_char = "mei_angry_v2.png" if loading else "mei_thinking_v2.png"
        right_char = "manchas_warning_v2.png" if loading else "manchas_excited_v2.png"
    else:
        canvas = gradient_background(GUIDE_SIZE, (230, 245, 243), (255, 245, 236))
        add_glow(canvas, (270, 232), 240, (167, 232, 224), 116)
        add_glow(canvas, (1248, 228), 260, (255, 215, 162), 110)
        panel_fill = (251, 252, 251, 232)
        accent_left = (93, 176, 191)
        accent_center = (242, 188, 86)
        accent_right = (118, 204, 179)
        left_char = "tikki_excited_v2.png" if loading else "tikki_proud_v2.png"
        center_char = "mei_happy_v2.png" if loading else "mei_proud_v2.png"
        right_char = "manchas_excited_v2.png" if loading else "manchas_proud_v2.png"

    rounded_panel(canvas, (118, 110, 1416, 914), panel_fill, (208, 228, 225, 255), radius=72)
    inner = ImageDraw.Draw(canvas)
    inner.rounded_rectangle((174, 154, 1360, 858), radius=56, outline=(224, 235, 233, 255), width=3)

    add_glow(canvas, (768, 720), 220, (182, 219, 228), 74)
    paste_character(canvas, left_char, (154, 290, 486, 780), shadow_alpha=64)
    paste_character(canvas, center_char, (502, 230, 1028, 812), shadow_alpha=76)
    paste_character(canvas, right_char, (1032, 290, 1388, 790), shadow_alpha=64)

    for x, accent in ((300, accent_left), (768, accent_center), (1228, accent_right)):
        inner.ellipse((x - 70, 730, x + 70, 870), fill=accent + (255,))
        inner.arc((x - 54, 746, x + 54, 852), start=14, end=332, fill=(232, 234, 234, 255), width=6)
        inner.arc((x - 40, 758, x + 40, 840), start=20, end=326, fill=(196, 202, 204, 255), width=4)

    if theme == "halloween":
        draw = ImageDraw.Draw(canvas)
        draw_pumpkin(draw, (272, 842), 36)
        draw_pumpkin(draw, (1260, 838), 34)
        draw_firework(draw, (774, 170), 26, (255, 197, 120))
        add_sparkles(canvas, [(226, 170), (458, 242), (1088, 204), (1324, 258), (1266, 640)], (255, 202, 112))
    else:
        draw = ImageDraw.Draw(canvas)
        draw_gift(draw, (196, 786, 292, 886), (222, 91, 91))
        draw_gift(draw, (1180, 784, 1276, 884), (94, 178, 150))
        for point in [(226, 168), (454, 242), (780, 162), (1092, 204), (1320, 258), (1268, 640)]:
            draw_snowflake(draw, point, 18, (255, 255, 255))
        add_sparkles(canvas, [(298, 214), (684, 194), (1182, 212), (1336, 640)], (255, 210, 128))

    return canvas


def draw_coin_stack(draw: ImageDraw.ImageDraw, base_center: tuple[int, int], count: int, accent: tuple[int, int, int]) -> None:
    x, y = base_center
    for index in range(count):
        offset_y = y - index * 14
        draw.rounded_rectangle(
            (x - 42, offset_y - 14, x + 42, offset_y + 12),
            radius=12,
            fill=(255, 229, 164, 255),
            outline=(224, 177, 74, 255),
            width=3,
        )
        draw.ellipse((x - 14, offset_y - 8, x + 14, offset_y + 16), fill=accent + (255,), outline=(255, 250, 234, 255), width=3)


def draw_savings_panel(
    canvas: Image.Image,
    box: tuple[int, int, int, int],
    accent: tuple[int, int, int],
    secondary: tuple[int, int, int],
) -> None:
    rounded_panel(canvas, box, (250, 252, 251, 232), (210, 228, 225, 255), radius=36)
    draw = ImageDraw.Draw(canvas)
    x0, y0, x1, y1 = box

    draw.rounded_rectangle((x0 + 28, y0 + 28, x1 - 28, y0 + 112), radius=24, fill=(255, 249, 236, 255), outline=(226, 225, 214, 255), width=2)
    draw.rounded_rectangle((x0 + 56, y0 + 60, x1 - 104, y0 + 82), radius=10, fill=(229, 240, 238, 255))
    draw.rounded_rectangle((x0 + 56, y0 + 60, x0 + int((x1 - x0) * 0.62), y0 + 82), radius=10, fill=accent + (255,))
    draw.ellipse((x1 - 92, y0 + 44, x1 - 44, y0 + 92), fill=secondary + (255,))

    for row, width_scale in enumerate((0.72, 0.58, 0.8), start=0):
        top = y0 + 152 + row * 92
        draw.rounded_rectangle((x0 + 30, top, x1 - 30, top + 68), radius=20, fill=(248, 251, 250, 255), outline=(219, 231, 228, 255), width=2)
        draw.ellipse((x0 + 56, top + 18, x0 + 92, top + 54), fill=accent + (255,))
        draw.rounded_rectangle((x0 + 114, top + 18, x1 - 94, top + 34), radius=8, fill=(225, 236, 236, 255))
        draw.rounded_rectangle((x0 + 114, top + 42, x1 - 126, top + 56), radius=8, fill=(237, 242, 242, 255))
        bar_right = x0 + 114 + int((x1 - x0 - 208) * width_scale)
        draw.rounded_rectangle((x0 + 114, top + 42, bar_right, top + 56), radius=8, fill=secondary + (255,))


def create_character_spotlight(theme: str, character_id: str) -> Image.Image:
    if theme == "halloween":
        top = (246, 232, 219)
        bottom = (69, 75, 90)
        accent = (255, 160, 78)
        secondary = (116, 203, 173)
        glow = (255, 197, 124)
        character_map = {
            "tikki": "tikki_confused_v2.png",
            "mei": "mei_warning_v2.png",
            "manchas": "manchas_warning_v2.png",
        }
    elif theme == "holiday":
        top = (232, 246, 244)
        bottom = (255, 245, 236)
        accent = (222, 90, 90)
        secondary = (97, 180, 151)
        glow = (255, 214, 164)
        character_map = {
            "tikki": "tikki_proud_v2.png",
            "mei": "mei_proud_v2.png",
            "manchas": "manchas_excited_v2.png",
        }
    else:
        top = (229, 242, 250)
        bottom = (255, 242, 229)
        accent = (93, 170, 210)
        secondary = (255, 184, 84)
        glow = (255, 216, 152)
        character_map = {
            "tikki": "tikki_excited_v2.png",
            "mei": "mei_excited_v2.png",
            "manchas": "manchas_proud_v2.png",
        }

    canvas = gradient_background(GUIDE_SIZE, top, bottom)
    add_glow(canvas, (280, 236), 250, glow, 118)
    add_glow(canvas, (1234, 248), 260, glow, 104)
    rounded_panel(canvas, (108, 108, 1428, 916), (251, 252, 251, 228), (208, 228, 225, 255), radius=72)
    rounded_panel(canvas, (154, 170, 700, 856), (247, 250, 249, 240), (214, 228, 226, 255), radius=48)
    draw_savings_panel(canvas, (188, 214, 666, 812), accent, secondary)
    paste_character(canvas, character_map[character_id], (736, 176, 1382, 888), shadow_alpha=72)
    draw = ImageDraw.Draw(canvas)

    if theme == "halloween":
        draw_pumpkin(draw, (244, 848), 34)
        draw_pumpkin(draw, (1288, 844), 32)
        draw_firework(draw, (1160, 194), 28, (255, 206, 125))
        add_sparkles(canvas, [(244, 170), (454, 202), (878, 196), (1288, 230), (1326, 706)], (255, 204, 114))
    elif theme == "holiday":
        draw_gift(draw, (210, 784, 304, 880), (220, 92, 92))
        draw_gift(draw, (1204, 786, 1298, 880), (96, 176, 148))
        for point in [(234, 168), (418, 220), (836, 188), (1192, 206), (1318, 250), (1284, 708)]:
            draw_snowflake(draw, point, 18, (255, 255, 255))
        add_sparkles(canvas, [(312, 210), (536, 198), (1114, 214), (1334, 694)], (255, 210, 128))
    else:
        draw_coin_stack(draw, (252, 850), 3, accent)
        draw_coin_stack(draw, (1268, 848), 2, secondary)
        draw_firework(draw, (1072, 176), 36, (255, 196, 96))
        draw_firework(draw, (1242, 214), 28, accent)
        add_sparkles(canvas, [(298, 188), (488, 214), (864, 190), (1174, 210), (1328, 694)], (255, 214, 132))

    return canvas


def create_event_badge(theme: str) -> Image.Image:
    canvas = Image.new("RGBA", (BADGE_SIZE, BADGE_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)

    if theme == "halloween":
        outer = ((84, 46, 37), (255, 161, 74))
        ring = (255, 210, 124)
    elif theme == "holiday":
        outer = ((26, 107, 95), (229, 87, 87))
        ring = (255, 228, 178)
    else:
        outer = ((42, 97, 128), (255, 183, 82))
        ring = (255, 232, 184)

    background = gradient_background((BADGE_SIZE, BADGE_SIZE), outer[0], outer[1])
    mask = Image.new("L", (BADGE_SIZE, BADGE_SIZE), 0)
    ImageDraw.Draw(mask).ellipse((36, 36, BADGE_SIZE - 36, BADGE_SIZE - 36), fill=255)
    background.putalpha(mask)
    canvas.alpha_composite(background)

    draw.ellipse((44, 44, BADGE_SIZE - 44, BADGE_SIZE - 44), outline=ring + (255,), width=18)
    draw.ellipse((78, 78, BADGE_SIZE - 78, BADGE_SIZE - 78), fill=(255, 249, 236, 215), outline=(255, 255, 255, 140), width=4)
    add_glow(canvas, (256, 158), 120, ring, 86)

    if theme == "halloween":
        draw_pumpkin(draw, (256, 292), 78)
        draw_firework(draw, (176, 180), 30, (255, 220, 144))
        draw.line((312, 180, 344, 138), fill=(255, 220, 144, 255), width=8)
        draw.ellipse((344, 124, 388, 168), fill=(255, 231, 189, 255))
    elif theme == "holiday":
        draw_gift(draw, (170, 188, 344, 360), (206, 76, 82))
        for point in [(176, 148), (334, 152), (256, 112)]:
            draw_snowflake(draw, point, 18, (255, 255, 255))
    else:
        draw_firework(draw, (256, 236), 82, (255, 196, 94))
        draw_firework(draw, (184, 312), 46, (109, 181, 204))
        draw_firework(draw, (330, 312), 46, (255, 214, 145))

    return canvas


def main() -> None:
    GUIDE_ROOT.mkdir(parents=True, exist_ok=True)
    BADGE_ROOT.mkdir(parents=True, exist_ok=True)

    guide_outputs = {
        "guide_01_dashboard_game_manchas_v2.png": create_dashboard_scene("base"),
        "guide_01_dashboard_game_manchas_halloween_v2.png": create_dashboard_scene("halloween"),
        "guide_01_dashboard_game_manchas_holiday_v2.png": create_dashboard_scene("holiday"),
        "guide_25_splash_team_halloween_v2.png": create_team_scene("halloween", loading=False),
        "guide_25_splash_team_holiday_v2.png": create_team_scene("holiday", loading=False),
        "guide_26_loading_yarn_team_halloween_v2.png": create_team_scene("halloween", loading=True),
        "guide_26_loading_yarn_team_holiday_v2.png": create_team_scene("holiday", loading=True),
        "guide_27_tikki_halloween_v2.png": create_character_spotlight("halloween", "tikki"),
        "guide_28_mei_halloween_v2.png": create_character_spotlight("halloween", "mei"),
        "guide_29_manchas_halloween_v2.png": create_character_spotlight("halloween", "manchas"),
        "guide_30_tikki_holiday_v2.png": create_character_spotlight("holiday", "tikki"),
        "guide_31_mei_holiday_v2.png": create_character_spotlight("holiday", "mei"),
        "guide_32_manchas_holiday_v2.png": create_character_spotlight("holiday", "manchas"),
        "guide_33_tikki_new_year_v2.png": create_character_spotlight("newyear", "tikki"),
        "guide_34_mei_new_year_v2.png": create_character_spotlight("newyear", "mei"),
        "guide_35_manchas_new_year_v2.png": create_character_spotlight("newyear", "manchas"),
    }

    for filename, image in guide_outputs.items():
        path = GUIDE_ROOT / filename
        image.save(path)
        print(f"updated {path}")

    badge_outputs = {
        "badge_event_halloween_v2.png": create_event_badge("halloween"),
        "badge_event_holiday_v2.png": create_event_badge("holiday"),
        "badge_event_new_year_v2.png": create_event_badge("newyear"),
    }

    for filename, image in badge_outputs.items():
        path = BADGE_ROOT / filename
        image.save(path)
        print(f"updated {path}")


if __name__ == "__main__":
    main()
