#!/usr/bin/env python3

from __future__ import annotations

import json
import math
import os
import tempfile
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
BRAND_ROOT = ROOT / "SpendSage" / "Resources" / "Brand" / "v2"
CHAR_ROOT = BRAND_ROOT / "characters"
GUIDE_ROOT = BRAND_ROOT / "guides"
LOGO_ROOT = BRAND_ROOT / "logo"
APPICON_ROOT = ROOT / "SpendSage" / "Resources" / "Assets.xcassets" / "AppIcon.appiconset"

ICON_SIZE = 1024
SPLASH_SIZE = 1024


def lerp(a: int, b: int, t: float) -> int:
    return int(round(a + (b - a) * t))


def vertical_gradient(size: int, top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    image = Image.new("RGBA", (size, size))
    draw = ImageDraw.Draw(image)
    for y in range(size):
        t = y / max(size - 1, 1)
        color = tuple(lerp(top[i], bottom[i], t) for i in range(3)) + (255,)
        draw.line((0, y, size, y), fill=color)
    return image


def add_glow(canvas: Image.Image, center: tuple[int, int], radius: int, color: tuple[int, int, int], alpha: int) -> None:
    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    x, y = center
    draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=color + (alpha,))
    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=radius // 2))
    canvas.alpha_composite(overlay)


def add_shadow(canvas: Image.Image, box: tuple[int, int, int, int], alpha: int = 60) -> None:
    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    draw.ellipse(box, fill=(20, 35, 38, alpha))
    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=16))
    canvas.alpha_composite(overlay)


def paste_image(
    canvas: Image.Image,
    image: Image.Image,
    box: tuple[int, int, int, int],
    *,
    align_bottom: bool = True,
) -> None:
    target_w = box[2] - box[0]
    target_h = box[3] - box[1]
    sprite = image.copy()
    sprite.thumbnail((target_w, target_h), Image.LANCZOS)
    x = box[0] + (target_w - sprite.width) // 2
    y = box[1] + (target_h - sprite.height if align_bottom else (target_h - sprite.height) // 2)
    canvas.alpha_composite(sprite, (x, y))


def paste_sprite(canvas: Image.Image, filename: str, box: tuple[int, int, int, int]) -> None:
    sprite = Image.open(CHAR_ROOT / filename).convert("RGBA")
    paste_image(canvas, sprite, box)


def cropped_sprite(filename: str) -> Image.Image:
    sprite = Image.open(CHAR_ROOT / filename).convert("RGBA")
    bbox = sprite.getbbox()
    if bbox is None:
        return sprite
    return sprite.crop(bbox)


def relative_crop(
    sprite: Image.Image,
    left: float = 0.0,
    top: float = 0.0,
    right: float = 1.0,
    bottom: float = 1.0,
) -> Image.Image:
    width, height = sprite.size
    crop_box = (
        int(width * left),
        int(height * top),
        int(width * right),
        int(height * bottom),
    )
    return sprite.crop(crop_box)


def prepared_sprite(
    filename: str,
    *,
    crop: tuple[float, float, float, float] | None = None,
    ellipse_mask: tuple[float, float, float, float] | None = None,
    mirror: bool = False,
    tint: tuple[int, int, int] | None = None,
    monochrome: tuple[tuple[int, int, int], tuple[int, int, int]] | None = None,
    alpha_scale: float = 1.0,
    fade_bottom_start: float | None = None,
) -> Image.Image:
    sprite = cropped_sprite(filename)
    if crop is not None:
        sprite = relative_crop(sprite, *crop)
    if mirror:
        sprite = ImageOps.mirror(sprite)

    red, green, blue, alpha = sprite.split()
    alpha = alpha.point(lambda value: int(max(0, min(255, value * alpha_scale))))

    if fade_bottom_start is not None:
        fade = Image.new("L", sprite.size, 255)
        fade_draw = ImageDraw.Draw(fade)
        start_y = int(max(0, min(sprite.height - 1, round(sprite.height * fade_bottom_start))))
        fade_height = max(sprite.height - start_y - 1, 1)
        for y in range(start_y, sprite.height):
            t = (y - start_y) / fade_height
            opacity = int(round(255 * max(0.0, 1 - t)))
            fade_draw.line((0, y, sprite.width, y), fill=opacity)
        alpha = ImageChops.multiply(alpha, fade)

    if ellipse_mask is not None:
        mask = Image.new("L", sprite.size, 0)
        mask_draw = ImageDraw.Draw(mask)
        left, top, right, bottom = ellipse_mask
        mask_draw.ellipse(
            (
                int(sprite.width * left),
                int(sprite.height * top),
                int(sprite.width * right),
                int(sprite.height * bottom),
            ),
            fill=255,
        )
        mask = mask.filter(ImageFilter.GaussianBlur(radius=max(2, sprite.width // 64)))
        alpha = ImageChops.multiply(alpha, mask)

    if monochrome is not None:
        light, dark = monochrome
        luminance = ImageOps.autocontrast(Image.merge("RGB", (red, green, blue)).convert("L"))
        colorized = ImageOps.colorize(luminance, black=dark, white=light).convert("RGBA")
        colorized.putalpha(alpha)
        return colorized

    if tint is not None:
        tinted = Image.new("RGBA", sprite.size, tint + (0,))
        tinted.putalpha(alpha)
        return tinted

    return Image.merge("RGBA", (red, green, blue, alpha))


def paste_peeking_sprite(
    canvas: Image.Image,
    filename: str,
    box: tuple[int, int, int, int],
    *,
    crop: tuple[float, float, float, float],
    ellipse_mask: tuple[float, float, float, float] | None = None,
    mirror: bool = False,
    tint: tuple[int, int, int] | None = None,
    monochrome: tuple[tuple[int, int, int], tuple[int, int, int]] | None = None,
    alpha_scale: float = 1.0,
    align_bottom: bool = False,
    fade_bottom_start: float | None = None,
) -> None:
    sprite = prepared_sprite(
        filename,
        crop=crop,
        ellipse_mask=ellipse_mask,
        mirror=mirror,
        tint=tint,
        monochrome=monochrome,
        alpha_scale=alpha_scale,
        fade_bottom_start=fade_bottom_start,
    )
    paste_image(canvas, sprite, box, align_bottom=align_bottom)


def draw_coin(draw: ImageDraw.ImageDraw, center: tuple[int, int], radius: int) -> None:
    x, y = center
    draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=(255, 209, 88, 255), outline=(212, 144, 28, 255), width=10)
    draw.ellipse((x - radius + 26, y - radius + 26, x + radius - 26, y + radius - 26), outline=(255, 236, 181, 255), width=8)
    draw.ellipse((x - 18, y - 18, x + 18, y + 18), fill=(255, 236, 181, 255), outline=(212, 144, 28, 255), width=6)


def draw_twinkle(
    draw: ImageDraw.ImageDraw,
    center: tuple[int, int],
    size: int,
    *,
    fill: tuple[int, int, int, int],
    width: int = 4,
) -> None:
    x, y = center
    draw.line((x - size, y, x + size, y), fill=fill, width=width)
    draw.line((x, y - size, x, y + size), fill=fill, width=width)


def draw_soft_panel(
    canvas: Image.Image,
    outer_box: tuple[int, int, int, int],
    *,
    radius: int,
    fill: tuple[int, int, int, int],
    outline: tuple[int, int, int, int],
    inner_inset: int = 34,
    inner_outline: tuple[int, int, int, int] | None = None,
) -> None:
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle(outer_box, radius=radius, fill=fill, outline=outline, width=4)
    if inner_outline is not None:
        inner_box = (
            outer_box[0] + inner_inset,
            outer_box[1] + inner_inset,
            outer_box[2] - inner_inset,
            outer_box[3] - inner_inset,
        )
        draw.rounded_rectangle(inner_box, radius=max(28, radius - inner_inset), outline=inner_outline, width=2)


def draw_ledge(
    canvas: Image.Image,
    box: tuple[int, int, int, int],
    *,
    fill: tuple[int, int, int, int],
    outline: tuple[int, int, int, int],
    top_highlight: tuple[int, int, int, int],
    shadow_alpha: int,
) -> None:
    add_shadow(canvas, (box[0] + 52, box[1] + 10, box[2] - 52, box[3] + 30), alpha=max(18, shadow_alpha - 12))
    draw = ImageDraw.Draw(canvas)
    radius = min((box[2] - box[0]) // 5, (box[3] - box[1]) // 2)
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=3)
    draw.line((box[0] + 44, box[1] + 8, box[2] - 44, box[1] + 8), fill=(255, 255, 255, max(54, top_highlight[3] + 24)), width=2)


def create_manchas_icon(
    *,
    background_top: tuple[int, int, int],
    background_bottom: tuple[int, int, int],
    panel_fill: tuple[int, int, int, int],
    panel_outline: tuple[int, int, int, int],
    inner_outline: tuple[int, int, int, int],
    ledge_fill: tuple[int, int, int, int],
    ledge_outline: tuple[int, int, int, int],
    ledge_highlight: tuple[int, int, int, int],
    orb_left: tuple[int, int, int, int],
    orb_right: tuple[int, int, int, int],
    glow_left: tuple[int, int, int],
    glow_right: tuple[int, int, int],
    twinkle_fill: tuple[int, int, int, int],
    monochrome: tuple[tuple[int, int, int], tuple[int, int, int]] | None = None,
) -> Image.Image:
    canvas = vertical_gradient(ICON_SIZE, background_top, background_bottom)
    add_glow(canvas, (232, 194), 220, glow_left, 118)
    add_glow(canvas, (810, 214), 206, glow_right, 102)
    add_glow(canvas, (514, 340), 172, (34, 52, 58), 28)
    add_glow(canvas, (262, 824), 182, (194, 228, 238), 44)
    draw = ImageDraw.Draw(canvas)

    draw_soft_panel(
        canvas,
        (74, 74, 950, 950),
        radius=258,
        fill=panel_fill,
        outline=panel_outline,
        inner_outline=inner_outline,
    )

    draw.ellipse((144, 146, 414, 390), fill=orb_left)
    draw.ellipse((640, 134, 890, 374), fill=orb_right)
    draw.ellipse((238, 764, 436, 906), fill=(255, 255, 255, 20))

    for center, size in (((208, 184), 16), ((794, 192), 14), ((312, 298), 10), ((724, 308), 10), ((836, 300), 8)):
        draw_twinkle(draw, center, size, fill=twinkle_fill, width=3 if size <= 10 else 4)

    paste_peeking_sprite(
        canvas,
        "manchas_neutral_v2.png",
        (206, 98, 818, 590),
        crop=(0.13, 0.0, 0.87, 0.56),
        ellipse_mask=(-0.08, -0.04, 1.08, 1.10),
        monochrome=monochrome,
    )

    draw_ledge(
        canvas,
        (176, 686, 848, 722),
        fill=ledge_fill,
        outline=ledge_outline,
        top_highlight=ledge_highlight,
        shadow_alpha=46 if monochrome is None else 38,
    )

    paste_peeking_sprite(
        canvas,
        "manchas_neutral_v2.png",
        (244, 620, 366, 720),
        crop=(0.20, 0.88, 0.31, 0.985),
        monochrome=monochrome,
        align_bottom=True,
    )
    paste_peeking_sprite(
        canvas,
        "manchas_neutral_v2.png",
        (658, 620, 780, 720),
        crop=(0.69, 0.88, 0.80, 0.985),
        monochrome=monochrome,
        align_bottom=True,
    )

    return canvas


def draw_yarn_ball(
    canvas: Image.Image,
    center: tuple[int, int],
    radius: int,
    fill: tuple[int, int, int],
    *,
    show_tail: bool = True,
) -> None:
    x, y = center
    add_shadow(canvas, (x - radius, y + radius // 2, x + radius, y + radius + radius // 2), alpha=52)

    draw = ImageDraw.Draw(canvas)
    draw.ellipse(
        (x - radius, y - radius, x + radius, y + radius),
        fill=fill + (255,),
        outline=(255, 255, 255, 110),
        width=max(3, radius // 12),
    )
    draw.ellipse(
        (x - radius + radius // 5, y - radius + radius // 5, x + radius - radius // 5, y + radius - radius // 5),
        outline=(255, 248, 230, 96),
        width=max(2, radius // 15),
    )
    draw.ellipse(
        (x - radius + radius // 3, y - radius + radius // 3, x - radius + int(radius * 0.8), y - radius + int(radius * 0.8)),
        fill=(255, 255, 255, 54),
    )
    draw.ellipse(
        (x - int(radius * 0.94), y - int(radius * 0.08), x + int(radius * 0.98), y + int(radius * 1.04)),
        fill=(80, 62, 40, 12),
    )
    draw.ellipse(
        (x - int(radius * 0.30), y + int(radius * 0.08), x + int(radius * 0.86), y + int(radius * 0.98)),
        fill=(124, 92, 42, 10),
    )

    thread_overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    detail = ImageDraw.Draw(thread_overlay)
    strand_specs = [
        ([(x - int(radius * 0.90), y - int(radius * 0.22)), (x - int(radius * 0.34), y - int(radius * 0.54)), (x + int(radius * 0.22), y - int(radius * 0.40)), (x + int(radius * 0.86), y - int(radius * 0.14))], (255, 250, 240, 156), max(2, radius // 8)),
        ([(x - int(radius * 0.92), y + int(radius * 0.04)), (x - int(radius * 0.28), y - int(radius * 0.20)), (x + int(radius * 0.18), y - int(radius * 0.04)), (x + int(radius * 0.86), y + int(radius * 0.10))], (255, 250, 240, 148), max(2, radius // 8)),
        ([(x - int(radius * 0.86), y + int(radius * 0.26)), (x - int(radius * 0.24), y + int(radius * 0.02)), (x + int(radius * 0.22), y + int(radius * 0.14)), (x + int(radius * 0.82), y + int(radius * 0.32))], (255, 246, 228, 142), max(2, radius // 8)),
        ([(x - int(radius * 0.76), y + int(radius * 0.50)), (x - int(radius * 0.16), y + int(radius * 0.26)), (x + int(radius * 0.32), y + int(radius * 0.40)), (x + int(radius * 0.74), y + int(radius * 0.58))], (255, 244, 220, 130), max(2, radius // 9)),
        ([(x - int(radius * 0.62), y - int(radius * 0.84)), (x - int(radius * 0.26), y - int(radius * 0.34)), (x - int(radius * 0.06), y + int(radius * 0.04)), (x + int(radius * 0.12), y + int(radius * 0.82))], (255, 246, 232, 120), max(2, radius // 11)),
        ([(x - int(radius * 0.30), y - int(radius * 0.88)), (x - int(radius * 0.02), y - int(radius * 0.34)), (x + int(radius * 0.18), y + int(radius * 0.06)), (x + int(radius * 0.34), y + int(radius * 0.84))], (255, 244, 224, 112), max(2, radius // 12)),
        ([(x + int(radius * 0.02), y - int(radius * 0.84)), (x + int(radius * 0.16), y - int(radius * 0.30)), (x + int(radius * 0.12), y + int(radius * 0.10)), (x - int(radius * 0.02), y + int(radius * 0.84))], (204, 122, 42, 86), max(2, radius // 13)),
        ([(x + int(radius * 0.42), y - int(radius * 0.80)), (x + int(radius * 0.24), y - int(radius * 0.24)), (x + int(radius * 0.04), y + int(radius * 0.12)), (x - int(radius * 0.24), y + int(radius * 0.74))], (192, 114, 38, 82), max(2, radius // 14)),
    ]
    for points, color, width in strand_specs:
        shadow_points = [(px, py + max(1, radius // 18)) for px, py in points]
        detail.line(shadow_points, fill=(56, 42, 28, 44), width=max(1, width - 1), joint="curve")
        detail.line(points, fill=color, width=width, joint="curve")

    for angle in (-38, -18, 6, 24, 44):
        width = int(radius * (1.36 - abs(angle) / 110))
        height = int(radius * (0.42 + abs(angle) / 180))
        arc_box = (x - width, y - height, x + width, y + height)
        detail.arc(arc_box, start=200, end=338, fill=(255, 248, 236, 82), width=max(2, radius // 12))

    for fiber_index in range(16):
        fiber_angle = math.radians(-62 + fiber_index * 8)
        inner = radius * 0.18
        outer = radius * (0.76 + (fiber_index % 3) * 0.04)
        start_point = (
            x + int(math.cos(fiber_angle) * inner),
            y + int(math.sin(fiber_angle) * inner),
        )
        end_point = (
            x + int(math.cos(fiber_angle) * outer),
            y + int(math.sin(fiber_angle) * outer),
        )
        fiber_color = (255, 244, 226, 72) if fiber_index % 2 == 0 else (170, 108, 38, 56)
        detail.line((start_point, end_point), fill=fiber_color, width=max(1, radius // 18))

    if show_tail:
        tail_shadow = [
            (x + int(radius * 0.34), y + int(radius * 0.58)),
            (x + int(radius * 0.92), y + int(radius * 0.66)),
            (x + int(radius * 0.88), y + int(radius * 1.16)),
            (x + int(radius * 0.42), y + int(radius * 1.22)),
        ]
        tail_highlight = [
            (x + int(radius * 0.28), y + int(radius * 0.52)),
            (x + int(radius * 0.88), y + int(radius * 0.58)),
            (x + int(radius * 0.84), y + int(radius * 1.08)),
            (x + int(radius * 0.34), y + int(radius * 1.14)),
        ]
        detail.line(tail_shadow, fill=(44, 30, 20, 62), width=max(3, radius // 8), joint="curve")
        detail.line(tail_highlight, fill=fill + (232,), width=max(2, radius // 11), joint="curve")

    thread_overlay = thread_overlay.filter(ImageFilter.GaussianBlur(radius=max(1, radius // 30)))
    canvas.alpha_composite(thread_overlay)
    add_glow(canvas, center, int(radius * 1.05), fill, 18)


def save_without_alpha(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            dir=path.parent,
            prefix=f".{path.stem}-",
            suffix=path.suffix,
            delete=False,
        ) as handle:
            temp_path = Path(handle.name)

        image.convert("RGB").save(temp_path)
        os.replace(temp_path, path)
    finally:
        if temp_path is not None and temp_path.exists():
            temp_path.unlink(missing_ok=True)


def write_text_atomically(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            dir=path.parent,
            prefix=f".{path.stem}-",
            suffix=path.suffix,
            delete=False,
            mode="w",
            encoding="utf-8",
        ) as handle:
            handle.write(content)
            temp_path = Path(handle.name)

        os.replace(temp_path, path)
    finally:
        if temp_path is not None and temp_path.exists():
            temp_path.unlink(missing_ok=True)


def create_app_icon() -> Image.Image:
    return create_manchas_icon(
        background_top=(78, 182, 175),
        background_bottom=(244, 247, 243),
        panel_fill=(252, 252, 249, 58),
        panel_outline=(255, 255, 255, 50),
        inner_outline=(236, 245, 242, 38),
        ledge_fill=(246, 239, 228, 255),
        ledge_outline=(255, 255, 255, 118),
        ledge_highlight=(255, 255, 255, 34),
        orb_left=(255, 255, 255, 28),
        orb_right=(255, 244, 219, 38),
        glow_left=(186, 240, 230),
        glow_right=(255, 220, 175),
        twinkle_fill=(255, 236, 201, 166),
    )


def create_app_icon_dark() -> Image.Image:
    return create_manchas_icon(
        background_top=(22, 50, 60),
        background_bottom=(74, 128, 130),
        panel_fill=(250, 252, 249, 18),
        panel_outline=(236, 246, 244, 38),
        inner_outline=(236, 246, 244, 20),
        ledge_fill=(236, 228, 216, 248),
        ledge_outline=(255, 255, 255, 58),
        ledge_highlight=(255, 255, 255, 22),
        orb_left=(255, 255, 255, 10),
        orb_right=(255, 228, 168, 16),
        glow_left=(94, 174, 179),
        glow_right=(224, 186, 112),
        twinkle_fill=(236, 246, 244, 132),
    )


def create_app_icon_tinted() -> Image.Image:
    return create_manchas_icon(
        background_top=(46, 94, 102),
        background_bottom=(86, 152, 155),
        panel_fill=(255, 255, 255, 10),
        panel_outline=(255, 255, 255, 32),
        inner_outline=(255, 255, 255, 16),
        ledge_fill=(239, 230, 214, 236),
        ledge_outline=(255, 255, 255, 26),
        ledge_highlight=(255, 255, 255, 18),
        orb_left=(255, 255, 255, 12),
        orb_right=(255, 255, 255, 10),
        glow_left=(112, 190, 194),
        glow_right=(182, 216, 214),
        twinkle_fill=(244, 236, 224, 130),
        monochrome=((244, 236, 224), (27, 46, 54)),
    )


def create_splash_guide() -> Image.Image:
    canvas = vertical_gradient(SPLASH_SIZE, (233, 245, 244), (255, 244, 235))
    add_glow(canvas, (232, 226), 220, (173, 236, 227), 145)
    add_glow(canvas, (820, 190), 220, (255, 225, 165), 118)
    add_glow(canvas, (516, 772), 240, (189, 227, 243), 90)
    draw = ImageDraw.Draw(canvas)

    draw_soft_panel(
        canvas,
        (76, 92, 948, 930),
        radius=98,
        fill=(249, 252, 251, 232),
        outline=(210, 229, 224, 255),
        inner_inset=42,
        inner_outline=(232, 240, 238, 255),
    )

    draw_yarn_ball(canvas, (278, 646), 80, (99, 179, 191))
    draw_yarn_ball(canvas, (512, 678), 98, (255, 198, 96))
    draw_yarn_ball(canvas, (746, 646), 80, (121, 209, 191))

    add_shadow(canvas, (116, 500, 404, 684), alpha=30)
    add_shadow(canvas, (314, 526, 714, 746), alpha=32)
    add_shadow(canvas, (620, 500, 908, 684), alpha=30)

    paste_sprite(canvas, "tikki_proud_v2.png", (66, 70, 398, 694))
    paste_sprite(canvas, "mei_neutral_v2.png", (282, -8, 742, 796))
    paste_sprite(canvas, "manchas_proud_v2.png", (626, 64, 958, 694))

    for point, size in (((184, 174), 10), ((280, 228), 10), ((828, 188), 10), ((744, 256), 10), ((512, 138), 12), ((870, 608), 10), ((418, 188), 8)):
        draw_twinkle(draw, point, size, fill=(255, 205, 107, 190))

    return canvas


def create_loading_guide() -> Image.Image:
    canvas = vertical_gradient(SPLASH_SIZE, (236, 245, 245), (250, 239, 228))
    add_glow(canvas, (246, 214), 210, (176, 235, 227), 140)
    add_glow(canvas, (820, 224), 228, (255, 222, 161), 112)
    add_glow(canvas, (520, 786), 250, (170, 219, 232), 96)
    draw = ImageDraw.Draw(canvas)

    draw_soft_panel(
        canvas,
        (74, 86, 950, 940),
        radius=108,
        fill=(250, 252, 252, 240),
        outline=(209, 228, 224, 255),
        inner_inset=46,
        inner_outline=(230, 239, 237, 255),
    )

    for center, radius, color, tail in (
        ((250, 640), 84, (104, 182, 193), False),
        ((514, 672), 108, (255, 196, 96), True),
        ((778, 638), 84, (121, 208, 192), False),
    ):
        draw_yarn_ball(canvas, center, radius, color, show_tail=tail)

    add_shadow(canvas, (110, 474, 412, 708), alpha=30)
    add_shadow(canvas, (286, 494, 742, 786), alpha=32)
    add_shadow(canvas, (616, 472, 928, 706), alpha=30)

    paste_sprite(canvas, "tikki_excited_v2.png", (56, 48, 408, 720))
    paste_sprite(canvas, "mei_neutral_v2.png", (250, -26, 774, 830))
    paste_sprite(canvas, "manchas_excited_v2.png", (628, 44, 980, 722))

    for point, size in (((184, 176), 11), ((296, 238), 10), ((832, 190), 11), ((738, 258), 10), ((512, 138), 12), ((874, 606), 10), ((438, 852), 10), ((604, 194), 8)):
        draw_twinkle(draw, point, size, fill=(255, 208, 112, 190))

    return canvas


def write_universal_appicon_set(any_icon: Image.Image, dark_icon: Image.Image, tinted_icon: Image.Image) -> None:
    APPICON_ROOT.mkdir(parents=True, exist_ok=True)

    outputs = {
        "icon-any-1024.png": any_icon,
        "icon-dark-1024.png": dark_icon,
        "icon-tinted-1024.png": tinted_icon,
    }
    expected_files = set(outputs.keys())

    for filename, image in outputs.items():
        path = APPICON_ROOT / filename
        save_without_alpha(image, path)
        print(f"updated {path}")

    for stale in APPICON_ROOT.glob("*.png"):
        if stale.name not in expected_files:
            stale.unlink()

    contents = {
        "images": [
            {
                "filename": "icon-any-1024.png",
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024",
            },
            {
                "filename": "icon-dark-1024.png",
                "appearances": [
                    {
                        "appearance": "luminosity",
                        "value": "dark",
                    }
                ],
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024",
            },
            {
                "filename": "icon-tinted-1024.png",
                "appearances": [
                    {
                        "appearance": "luminosity",
                        "value": "tinted",
                    }
                ],
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024",
            },
        ],
        "info": {
            "author": "xcode",
            "version": 1,
        },
    }
    write_text_atomically(APPICON_ROOT / "Contents.json", f"{json.dumps(contents, indent=2)}\n")


def main() -> None:
    GUIDE_ROOT.mkdir(parents=True, exist_ok=True)
    LOGO_ROOT.mkdir(parents=True, exist_ok=True)

    splash = create_splash_guide()
    splash_path = GUIDE_ROOT / "guide_25_splash_team_v2.png"
    splash.save(splash_path)
    print(f"generated {splash_path}")

    loading = create_loading_guide()
    loading_path = GUIDE_ROOT / "guide_26_loading_yarn_team_v2.png"
    loading.save(loading_path)
    print(f"generated {loading_path}")

    icon = create_app_icon()
    icon_dark = create_app_icon_dark()
    icon_tinted = create_app_icon_tinted()

    logo_outputs = {
        "app_icon_v2.png": icon,
        "app_icon_dark_v2.png": icon_dark,
        "app_icon_tinted_v2.png": icon_tinted,
    }
    for filename, image in logo_outputs.items():
        path = LOGO_ROOT / filename
        save_without_alpha(image, path)
        print(f"generated {path}")

    write_universal_appicon_set(icon, icon_dark, icon_tinted)


if __name__ == "__main__":
    main()
