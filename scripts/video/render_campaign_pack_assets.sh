#!/bin/zsh

set -euo pipefail

ROOT="/Users/rubenlazaro/Projects/spensage-ios"
RAW_DIR="$ROOT/MarketingAssets/tutorial-series/raw"
GUIDES_DIR="$ROOT/SpendSage/Resources/Brand/v2/guides"
OUTPUT_DIR="$ROOT/MarketingAssets/tutorial-series/final-thumbnails"
FFMPEG_FULL_BIN="/opt/homebrew/opt/ffmpeg-full/bin/ffmpeg"
FFMPEG_BIN="${FFMPEG_BIN:-$([ -x "$FFMPEG_FULL_BIN" ] && echo "$FFMPEG_FULL_BIN" || command -v ffmpeg)}"
FONT_DISPLAY="${FONT_DISPLAY:-/System/Library/Fonts/SFCompactRounded.ttf}"
FONT_BODY="${FONT_BODY:-/System/Library/Fonts/SFNSRounded.ttf}"
ACCENT_COLOR="0x86F0E6"
SURFACE_COLOR="0x081415"
TEXT_COLOR="white"

mkdir -p "$OUTPUT_DIR"

typeset -a ALL_TUTORIALS=(
    tutorial_01_onboarding_first_win
    tutorial_02_home_y_agregar_gasto
    tutorial_03_escaneo_y_guardado
    tutorial_04_analisis_y_presupuesto
    tutorial_05_cuentas_facturas_reglas
    tutorial_06_ajustes_ayuda_y_planes
    tutorial_07_logro_y_share
)

usage() {
    cat <<'EOF'
Usage:
  scripts/video/render_campaign_pack_assets.sh render all
  scripts/video/render_campaign_pack_assets.sh render <tutorial_id>
  scripts/video/render_campaign_pack_assets.sh list
EOF
}

thumbnail_config() {
    case "$1" in
        tutorial_01_onboarding_first_win)
            TAG='1/7'
            TITLE_LINE_ONE='Empieza'
            TITLE_LINE_TWO='aquí'
            SUBLINE='Primeros pasos sin enredarte'
            SNAP_TIME='10.00'
            ;;
        tutorial_02_home_y_agregar_gasto)
            TAG='2/7'
            TITLE_LINE_ONE='Anota'
            TITLE_LINE_TWO='rápido'
            SUBLINE='Registra gastos en segundos'
            SNAP_TIME='14.00'
            ;;
        tutorial_03_escaneo_y_guardado)
            TAG='3/7'
            TITLE_LINE_ONE='Escanea'
            TITLE_LINE_TWO='y listo'
            SUBLINE='Recibos sin fricción'
            SNAP_TIME='12.00'
            ;;
        tutorial_04_analisis_y_presupuesto)
            TAG='4/7'
            TITLE_LINE_ONE='Usa tus'
            TITLE_LINE_TWO='datos'
            SUBLINE='Análisis y presupuesto claros'
            SNAP_TIME='13.00'
            ;;
        tutorial_05_cuentas_facturas_reglas)
            TAG='5/7'
            TITLE_LINE_ONE='Se acaba'
            TITLE_LINE_TWO='el caos'
            SUBLINE='Ordena cuentas y reglas'
            SNAP_TIME='21.00'
            ;;
        tutorial_06_ajustes_ayuda_y_planes)
            TAG='6/7'
            TITLE_LINE_ONE='Ubícate'
            TITLE_LINE_TWO='rápido'
            SUBLINE='Ayuda, ajustes y planes'
            SNAP_TIME='20.00'
            ;;
        tutorial_07_logro_y_share)
            TAG='7/7'
            TITLE_LINE_ONE='Comparte'
            TITLE_LINE_TWO='tu logro'
            SUBLINE='Logro y share en un toque'
            SNAP_TIME='18.00'
            ;;
        *)
            echo "Unknown tutorial id: $1" >&2
            exit 1
            ;;
    esac
}

assert_dependencies() {
    [[ -n "$FFMPEG_BIN" && -x "$FFMPEG_BIN" ]] || { echo "ffmpeg is required." >&2; exit 1; }
}

render_thumbnail() {
    local tutorial_id="$1"
    local input="$RAW_DIR/${tutorial_id}.mov"
    local output="$OUTPUT_DIR/${tutorial_id}_thumb.png"
    local tmpdir
    local tag_file
    local title_line_one_file
    local title_line_two_file
    local subline_file

    [[ -f "$input" ]] || { echo "Missing raw clip: $input" >&2; exit 1; }

    thumbnail_config "$tutorial_id"

    tmpdir="$(mktemp -d)"
    tag_file="$tmpdir/tag.txt"
    title_line_one_file="$tmpdir/title_line_one.txt"
    title_line_two_file="$tmpdir/title_line_two.txt"
    subline_file="$tmpdir/subline.txt"

    printf '%s' "$TAG" > "$tag_file"
    printf '%s' "$TITLE_LINE_ONE" > "$title_line_one_file"
    printf '%s' "$TITLE_LINE_TWO" > "$title_line_two_file"
    printf '%s' "$SUBLINE" > "$subline_file"

    "$FFMPEG_BIN" -y -ss "$SNAP_TIME" -i "$input" \
        -filter_complex "\
[0:v]split=2[bgsrc][fgsrc]; \
[bgsrc]scale=1280:720:force_original_aspect_ratio=increase,crop=1280:720,gblur=sigma=28,eq=brightness=-0.20:saturation=1.05[bg]; \
[fgsrc]scale=-1:610:flags=lanczos[fg]; \
[bg]drawbox=x=0:y=0:w=1280:h=720:color=${SURFACE_COLOR}@0.40:t=fill[bgwash]; \
[bgwash]drawbox=x=60:y=56:w=118:h=46:color=${ACCENT_COLOR}@0.14:t=fill[base1]; \
[base1]drawbox=x=60:y=56:w=118:h=46:color=${ACCENT_COLOR}@0.60:t=2[base2]; \
[base2]drawtext=fontfile='${FONT_BODY}':textfile='${tag_file}':reload=1:fontcolor=${ACCENT_COLOR}:fontsize=25:x=(60+(118-text_w)/2):y=69[base3]; \
[base3]drawbox=x=56:y=134:w=570:h=356:color=${SURFACE_COLOR}@0.86:t=fill[base4]; \
[base4]drawbox=x=56:y=134:w=570:h=356:color=white@0.10:t=2[base5]; \
[base5]drawbox=x=56:y=134:w=7:h=356:color=${ACCENT_COLOR}@0.95:t=fill[base6]; \
[base6]drawtext=fontfile='${FONT_DISPLAY}':textfile='${title_line_one_file}':reload=1:fontcolor=${TEXT_COLOR}:fontsize=72:shadowcolor=0x000000@0.44:shadowx=0:shadowy=5:x=90:y=178[base7]; \
[base7]drawtext=fontfile='${FONT_DISPLAY}':textfile='${title_line_two_file}':reload=1:fontcolor=${TEXT_COLOR}:fontsize=72:shadowcolor=0x000000@0.44:shadowx=0:shadowy=5:x=90:y=252[base8]; \
[base8]drawtext=fontfile='${FONT_BODY}':textfile='${subline_file}':reload=1:fontcolor=0xD6E9E8:fontsize=30:shadowcolor=0x000000@0.34:shadowx=0:shadowy=4:x=90:y=372[base9]; \
[base9]drawbox=x=804:y=42:w=400:h=636:color=0x000000@0.28:t=fill[base10]; \
[base10]drawbox=x=804:y=42:w=400:h=636:color=white@0.12:t=2[base11]; \
[base11][fg]overlay=x=864:y=55" \
        -frames:v 1 -update 1 "$output"

    rm -rf "$tmpdir"
}

render_playlist_cover() {
    local input="$GUIDES_DIR/guide_17_landing_hero_team_v2.png"
    local output="$OUTPUT_DIR/playlist_cover_spendsage_en_7_pasos.png"
    local tmpdir
    local kicker_file
    local title_line_one_file
    local title_line_two_file
    local subtitle_file

    [[ -f "$input" ]] || { echo "Missing playlist hero: $input" >&2; exit 1; }

    tmpdir="$(mktemp -d)"
    kicker_file="$tmpdir/kicker.txt"
    title_line_one_file="$tmpdir/title_line_one.txt"
    title_line_two_file="$tmpdir/title_line_two.txt"
    subtitle_file="$tmpdir/subtitle.txt"

    printf '%s' 'Serie tutorial' > "$kicker_file"
    printf '%s' 'SpendSage' > "$title_line_one_file"
    printf '%s' 'en 7 pasos' > "$title_line_two_file"
    printf '%s' 'Aprende la app rapido y sin enredarte' > "$subtitle_file"

    "$FFMPEG_BIN" -y -loop 1 -i "$input" \
        -filter_complex "\
[0:v]split=2[bgsrc][herosrc]; \
[bgsrc]scale=1280:720:force_original_aspect_ratio=increase,crop=1280:720,gblur=sigma=26,eq=brightness=-0.22:saturation=1.06[bg]; \
[herosrc]scale=580:580:force_original_aspect_ratio=decrease[hero]; \
[bg]drawbox=x=0:y=0:w=1280:h=720:color=${SURFACE_COLOR}@0.44:t=fill[base1]; \
[base1]drawbox=x=54:y=72:w=600:h=454:color=${SURFACE_COLOR}@0.86:t=fill[base2]; \
[base2]drawbox=x=54:y=72:w=600:h=454:color=white@0.10:t=2[base3]; \
[base3]drawbox=x=54:y=72:w=7:h=454:color=${ACCENT_COLOR}@0.95:t=fill[base4]; \
[base4]drawtext=fontfile='${FONT_BODY}':textfile='${kicker_file}':reload=1:fontcolor=${ACCENT_COLOR}:fontsize=30:x=92:y=122[base5]; \
[base5]drawtext=fontfile='${FONT_DISPLAY}':textfile='${title_line_one_file}':reload=1:fontcolor=${TEXT_COLOR}:fontsize=76:shadowcolor=0x000000@0.45:shadowx=0:shadowy=5:x=92:y=190[base6]; \
[base6]drawtext=fontfile='${FONT_DISPLAY}':textfile='${title_line_two_file}':reload=1:fontcolor=${TEXT_COLOR}:fontsize=76:shadowcolor=0x000000@0.45:shadowx=0:shadowy=5:x=92:y=272[base7]; \
[base7]drawtext=fontfile='${FONT_BODY}':textfile='${subtitle_file}':reload=1:fontcolor=0xD6E9E8:fontsize=32:x=92:y=394[base8]; \
[base8]drawbox=x=720:y=78:w=470:h=560:color=0x000000@0.22:t=fill[base9]; \
[base9]drawbox=x=720:y=78:w=470:h=560:color=white@0.10:t=2[base10]; \
[base10][hero]overlay=x=668:y=72" \
        -frames:v 1 -update 1 "$output"

    rm -rf "$tmpdir"
}

render_all() {
    local tutorial_id
    for tutorial_id in "${ALL_TUTORIALS[@]}"; do
        render_thumbnail "$tutorial_id"
    done
    render_playlist_cover
}

main() {
    assert_dependencies

    case "${1:-}" in
        render)
            case "${2:-}" in
                all)
                    render_all
                    ;;
                tutorial_*)
                    render_thumbnail "${2:-}"
                    render_playlist_cover
                    ;;
                *)
                    usage
                    exit 1
                    ;;
            esac
            ;;
        list)
            print -l "${ALL_TUTORIALS[@]}"
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
