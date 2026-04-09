from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageChops, ImageColor, ImageDraw, ImageFilter, ImageFont


ROOT = Path("/Users/rubenlazaro/Projects/spensage-ios")
OUTPUT_DIR = ROOT / "AppStoreAssets" / "external-release" / "iphone-6.9" / "es"
CONTACT_SHEET = ROOT / "AppStoreAssets" / "external-release" / "iphone-6.9" / "overview.png"

CANVAS = (1320, 2868)
SCREENSHOT_FRAME = (88, 660, 842, 2490)
RIGHT_RAIL_X = 930

FONT_HEAVY = "/System/Library/Fonts/SFNSRounded.ttf"
FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"


@dataclass(frozen=True)
class BlurRegion:
    x: float
    y: float
    w: float
    h: float


@dataclass(frozen=True)
class ShotSpec:
    slug: str
    source: str
    badge: str
    title: str
    subtitle: str
    background_top: str
    background_bottom: str
    accent: str
    primary_mascot: str
    sidekick_a: str
    sidekick_b: str
    blur_regions: tuple[BlurRegion, ...] = ()


SPECS: tuple[ShotSpec, ...] = (
    ShotSpec(
        slug="01_inicio_control.png",
        source=".qa-screens/codex-20260406/appstore/dashboard.png",
        badge="Inicio simple",
        title="Controla tu dinero\nsin enredos",
        subtitle="Mira lo importante del día, detecta presión en tu presupuesto y decide tu siguiente paso en segundos.",
        background_top="#F2FBFB",
        background_bottom="#D8F1EF",
        accent="#1F8C86",
        primary_mascot="SpendSage/Resources/Brand/v2/characters/manchas_proud_v2.png",
        sidekick_a="SpendSage/Resources/Brand/v2/characters/mei_happy_v2.png",
        sidekick_b="SpendSage/Resources/Brand/v2/characters/tikki_happy_v2.png",
        blur_regions=(
            BlurRegion(0.11, 0.29, 0.21, 0.08),
            BlurRegion(0.37, 0.29, 0.18, 0.08),
            BlurRegion(0.11, 0.44, 0.18, 0.08),
        ),
    ),
    ShotSpec(
        slug="02_gastos_rapidos.png",
        source=".qa-screens/codex-20260406/appstore/expenses.png",
        badge="Gastos al vuelo",
        title="Registra y organiza\ngastos rápido",
        subtitle="Captura el mes sin saturarte. Primero anotas, luego profundizas solo cuando hace falta.",
        background_top="#F5FBF8",
        background_bottom="#D9F3E6",
        accent="#2C8A61",
        primary_mascot="SpendSage/Resources/Brand/v2/characters/manchas_excited_v2.png",
        sidekick_a="SpendSage/Resources/Brand/v2/characters/mei_neutral_v2.png",
        sidekick_b="SpendSage/Resources/Brand/v2/characters/tikki_proud_v2.png",
        blur_regions=(
            BlurRegion(0.11, 0.40, 0.22, 0.08),
        ),
    ),
    ShotSpec(
        slug="03_scan_recibos.png",
        source=".qa-screens/full-routes-real/tab-scan.png",
        badge="Recibos en 3 pasos",
        title="Escanea recibos,\nrevisa y guarda",
        subtitle="Toma la foto, deja que la app te ayude a llenar el borrador y corrige lo que quieras antes de guardar.",
        background_top="#F6FBFF",
        background_bottom="#DCEFFF",
        accent="#3174B7",
        primary_mascot="SpendSage/Resources/Brand/v2/characters/mei_thinking_v2.png",
        sidekick_a="SpendSage/Resources/Brand/v2/characters/manchas_happy_v2.png",
        sidekick_b="SpendSage/Resources/Brand/v2/characters/tikki_excited_v2.png",
    ),
    ShotSpec(
        slug="04_analisis_claro.png",
        source=".qa-screens/codex-20260406/appstore/insights.png",
        badge="Análisis claro",
        title="Entiende qué cambió\nsin leer un reporte",
        subtitle="Toca una barra para ver el valor exacto, detectar focos de gasto y actuar con más calma.",
        background_top="#F7FAFF",
        background_bottom="#E2EEFF",
        accent="#386FB7",
        primary_mascot="SpendSage/Resources/Brand/v2/characters/mei_proud_v2.png",
        sidekick_a="SpendSage/Resources/Brand/v2/characters/manchas_neutral_v2.png",
        sidekick_b="SpendSage/Resources/Brand/v2/characters/tikki_thinking_v2.png",
    ),
    ShotSpec(
        slug="05_presupuesto_guiado.png",
        source=".qa-screens/budget-wizard-v3.png",
        badge="Presupuesto guiado",
        title="Arma tu plan\npaso a paso",
        subtitle="Define ingresos, ajusta tu meta mensual y aterriza un presupuesto que sí se sienta alcanzable.",
        background_top="#FFF9F3",
        background_bottom="#FFE7D3",
        accent="#C7742A",
        primary_mascot="SpendSage/Resources/Brand/v2/characters/tikki_excited_v2.png",
        sidekick_a="SpendSage/Resources/Brand/v2/characters/mei_happy_v2.png",
        sidekick_b="SpendSage/Resources/Brand/v2/characters/manchas_proud_v2.png",
    ),
    ShotSpec(
        slug="06_badges_y_racha.png",
        source=".qa-screens/celebration-level-20260405-v4.png",
        badge="Loop de progreso",
        title="Convierte ahorro en\nniveles, badges y rachas",
        subtitle="Celebra avances reales, comparte logros y mantén el impulso con una experiencia más viva y cute.",
        background_top="#FFF8FB",
        background_bottom="#F4E4FF",
        accent="#9A4CB6",
        primary_mascot="SpendSage/Resources/Brand/v2/characters/manchas_love_v2.png",
        sidekick_a="SpendSage/Resources/Brand/v2/characters/mei_excited_v2.png",
        sidekick_b="SpendSage/Resources/Brand/v2/characters/tikki_proud_v2.png",
    ),
)


def font(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size=size)


def make_gradient(size: tuple[int, int], top: str, bottom: str) -> Image.Image:
    width, height = size
    top_rgb = ImageColor.getrgb(top)
    bottom_rgb = ImageColor.getrgb(bottom)
    image = Image.new("RGBA", size)
    draw = ImageDraw.Draw(image)
    for y in range(height):
        t = y / max(height - 1, 1)
        color = tuple(int(top_rgb[i] * (1 - t) + bottom_rgb[i] * t) for i in range(3)) + (255,)
        draw.line((0, y, width, y), fill=color)
    return image


def add_glow(background: Image.Image, center: tuple[int, int], radius: int, color: str, opacity: int) -> None:
    layer = Image.new("RGBA", background.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    x, y = center
    draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=ImageColor.getrgb(color) + (opacity,))
    background.alpha_composite(layer.filter(ImageFilter.GaussianBlur(radius // 2)))


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask


def blur_regions(image: Image.Image, regions: Iterable[BlurRegion]) -> Image.Image:
    output = image.copy()
    width, height = image.size
    for region in regions:
        box = (
            int(region.x * width),
            int(region.y * height),
            int((region.x + region.w) * width),
            int((region.y + region.h) * height),
        )
        crop = output.crop(box).filter(ImageFilter.GaussianBlur(20))
        soft = Image.new("RGBA", crop.size, (255, 255, 255, 52))
        crop = Image.alpha_composite(crop.convert("RGBA"), soft)
        output.paste(crop.convert(output.mode), box)
    return output


def fit_inside(image: Image.Image, max_size: tuple[int, int]) -> Image.Image:
    copy = image.copy()
    copy.thumbnail(max_size, Image.Resampling.LANCZOS)
    return copy


def draw_multiline_text(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, font_obj, fill, spacing: int = 0) -> tuple[int, int]:
    draw.multiline_text(xy, text, font=font_obj, fill=fill, spacing=spacing)
    return draw.multiline_textbbox(xy, text, font=font_obj, spacing=spacing)[2:]


def wrap_text(draw: ImageDraw.ImageDraw, text: str, font_obj, max_width: int) -> str:
    words = text.split()
    if not words:
        return text
    lines: list[str] = []
    current = words[0]
    for word in words[1:]:
        candidate = f"{current} {word}"
        left, _, right, _ = draw.textbbox((0, 0), candidate, font=font_obj)
        if right - left <= max_width:
            current = candidate
        else:
            lines.append(current)
            current = word
    lines.append(current)
    return "\n".join(lines)


def add_shadow(base: Image.Image, rect: tuple[int, int, int, int], radius: int = 36, opacity: int = 44) -> None:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.rounded_rectangle(rect, radius=38, fill=(17, 31, 44, opacity))
    base.alpha_composite(layer.filter(ImageFilter.GaussianBlur(radius)))


def build_shot(spec: ShotSpec) -> Image.Image:
    canvas = make_gradient(CANVAS, spec.background_top, spec.background_bottom)
    add_glow(canvas, (200, 320), 220, "#FFFFFF", 130)
    add_glow(canvas, (1080, 540), 280, spec.accent, 54)
    add_glow(canvas, (1180, 2420), 200, spec.accent, 42)

    draw = ImageDraw.Draw(canvas)
    badge_font = font(FONT_BOLD, 44)
    title_font = font(FONT_HEAVY, 96)
    body_font = font(FONT_HEAVY, 42)

    badge_box = (86, 96, 430, 172)
    draw.rounded_rectangle(badge_box, radius=36, fill=(255, 255, 255, 230))
    draw.rounded_rectangle(badge_box, radius=36, outline=ImageColor.getrgb(spec.accent) + (40,), width=3)
    draw.text((118, 116), spec.badge, font=badge_font, fill=ImageColor.getrgb(spec.accent))

    draw.multiline_text((86, 220), spec.title, font=title_font, fill=(26, 42, 54), spacing=8)
    wrapped_subtitle = wrap_text(draw, spec.subtitle, body_font, max_width=730)
    draw.multiline_text((92, 470), wrapped_subtitle, font=body_font, fill=(73, 96, 112), spacing=10)

    screenshot = Image.open(ROOT / spec.source).convert("RGBA")
    screenshot = blur_regions(screenshot, spec.blur_regions)
    screenshot = fit_inside(screenshot, (SCREENSHOT_FRAME[2] - SCREENSHOT_FRAME[0], SCREENSHOT_FRAME[3] - SCREENSHOT_FRAME[1]))

    frame = Image.new("RGBA", (SCREENSHOT_FRAME[2] - SCREENSHOT_FRAME[0], SCREENSHOT_FRAME[3] - SCREENSHOT_FRAME[1]), (255, 255, 255, 0))
    add_shadow(canvas, (SCREENSHOT_FRAME[0] - 4, SCREENSHOT_FRAME[1] + 18, SCREENSHOT_FRAME[2] + 6, SCREENSHOT_FRAME[3] + 30))
    frame_draw = ImageDraw.Draw(frame)
    frame_draw.rounded_rectangle((0, 0, frame.width, frame.height), radius=58, fill=(255, 255, 255, 236))
    inner = Image.new("RGBA", (frame.width - 36, frame.height - 36), (255, 255, 255, 255))
    inner_draw = ImageDraw.Draw(inner)
    inner_draw.rounded_rectangle((0, 0, inner.width, inner.height), radius=48, fill=(250, 252, 253, 255))
    screenshot_x = (inner.width - screenshot.width) // 2
    screenshot_y = (inner.height - screenshot.height) // 2
    inner.alpha_composite(screenshot, (screenshot_x, screenshot_y))
    frame.alpha_composite(inner, (18, 18))
    frame.putalpha(rounded_mask(frame.size, 58))
    canvas.alpha_composite(frame, (SCREENSHOT_FRAME[0], SCREENSHOT_FRAME[1]))

    rail = Image.new("RGBA", (300, 860), (255, 255, 255, 0))
    rail_draw = ImageDraw.Draw(rail)
    rail_draw.rounded_rectangle((0, 40, rail.width, rail.height), radius=52, fill=(255, 255, 255, 170))
    rail_draw.rounded_rectangle((0, 40, rail.width, rail.height), radius=52, outline=(255, 255, 255, 150), width=2)
    rail = rail.filter(ImageFilter.GaussianBlur(0.2))
    canvas.alpha_composite(rail, (RIGHT_RAIL_X, 1040))

    primary = fit_inside(Image.open(ROOT / spec.primary_mascot).convert("RGBA"), (330, 330))
    side_a = fit_inside(Image.open(ROOT / spec.sidekick_a).convert("RGBA"), (156, 156))
    side_b = fit_inside(Image.open(ROOT / spec.sidekick_b).convert("RGBA"), (156, 156))

    canvas.alpha_composite(primary, (958, 1210))
    canvas.alpha_composite(side_a, (1018, 988))
    canvas.alpha_composite(side_b, (1138, 1888))

    quote_box = (914, 2098, 1238, 2356)
    draw.rounded_rectangle(quote_box, radius=42, fill=(255, 255, 255, 208))
    draw.rounded_rectangle(quote_box, radius=42, outline=ImageColor.getrgb(spec.accent) + (32,), width=2)
    quote_font = font(FONT_HEAVY, 35)
    draw.multiline_text(
        (946, 2140),
        "SpendSage\nte ayuda\nsin sentirse\ncomo una hoja\nde cálculo.",
        font=quote_font,
        fill=(40, 64, 78),
        spacing=6,
    )

    return canvas.convert("RGB")


def build_contact_sheet(images: list[tuple[str, Image.Image]]) -> Image.Image:
    tile_w = 540
    tile_h = 1172
    gutter = 36
    margin = 40
    columns = 2
    rows = (len(images) + columns - 1) // columns
    width = margin * 2 + columns * tile_w + (columns - 1) * gutter
    height = margin * 2 + rows * (tile_h + 78) + (rows - 1) * gutter
    sheet = make_gradient((width, height), "#F7FBFB", "#E4F0EF")
    draw = ImageDraw.Draw(sheet)
    label_font = font(FONT_HEAVY, 34)

    for index, (label, image) in enumerate(images):
        row = index // columns
        col = index % columns
        x = margin + col * (tile_w + gutter)
        y = margin + row * (tile_h + 78 + gutter)
        thumb = image.copy()
        thumb.thumbnail((tile_w, tile_h), Image.Resampling.LANCZOS)
        add_shadow(sheet, (x, y + 14, x + thumb.width, y + thumb.height + 14), radius=22, opacity=36)
        card = Image.new("RGBA", (thumb.width, thumb.height), (255, 255, 255, 255))
        card.putalpha(rounded_mask(card.size, 28))
        card.alpha_composite(thumb.convert("RGBA"))
        sheet.alpha_composite(card, (x, y))
        draw.text((x, y + thumb.height + 18), label, font=label_font, fill=(39, 61, 74))

    return sheet.convert("RGB")


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    outputs: list[tuple[str, Image.Image]] = []
    for spec in SPECS:
        image = build_shot(spec)
        image.save(OUTPUT_DIR / spec.slug, quality=95)
        outputs.append((spec.slug.replace(".png", ""), image))

    contact = build_contact_sheet(outputs)
    CONTACT_SHEET.parent.mkdir(parents=True, exist_ok=True)
    contact.save(CONTACT_SHEET, quality=95)


if __name__ == "__main__":
    main()
