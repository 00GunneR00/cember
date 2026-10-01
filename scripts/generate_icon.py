from PIL import Image, ImageDraw, ImageFilter
import math

SIZE = 1024
CENTER = SIZE / 2

WARM_HIGHLIGHT = (74, 59, 46)
WARM_DARK = (13, 10, 8)
WHITE = (255, 255, 255)
EMERALD = (16, 185, 129)
AMBER = (245, 158, 11)


def radial_gradient_background(size):
    img = Image.new("RGB", (size, size), WARM_DARK)
    px = img.load()
    max_dist = math.hypot(size * 0.75, size * 0.65)
    cx, cy = size * 0.32, size * 0.28
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - cx, y - cy) / max_dist
            d = min(1.0, d)
            t = d ** 1.15
            r = int(WARM_HIGHLIGHT[0] + (WARM_DARK[0] - WARM_HIGHLIGHT[0]) * t)
            g = int(WARM_HIGHLIGHT[1] + (WARM_DARK[1] - WARM_HIGHLIGHT[1]) * t)
            b = int(WARM_HIGHLIGHT[2] + (WARM_DARK[2] - WARM_HIGHLIGHT[2]) * t)
            px[x, y] = (r, g, b)
    return img


def draw_mark(draw, center, ring_outer_r, ring_stroke, accent_r, accent_offset_angle_deg):
    cx, cy = center
    draw.ellipse(
        [cx - ring_outer_r, cy - ring_outer_r, cx + ring_outer_r, cy + ring_outer_r],
        outline=EMERALD,
        width=ring_stroke,
    )
    angle = math.radians(accent_offset_angle_deg)
    ax = cx + ring_outer_r * math.cos(angle)
    ay = cy + ring_outer_r * math.sin(angle)
    draw.ellipse([ax - accent_r, ay - accent_r, ax + accent_r, ay + accent_r], fill=AMBER)
    draw.ellipse(
        [ax - accent_r * 0.4, ay - accent_r * 0.4, ax + accent_r * 0.4, ay + accent_r * 0.4],
        fill=WHITE,
    )


def build_full_icon():
    img = radial_gradient_background(SIZE)
    draw = ImageDraw.Draw(img)
    draw_mark(
        draw,
        (CENTER, CENTER * 0.98),
        ring_outer_r=SIZE * 0.255,
        ring_stroke=int(SIZE * 0.075),
        accent_r=SIZE * 0.062,
        accent_offset_angle_deg=-38,
    )
    img.save("assets/icon/icon.png")


def build_foreground():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_mark(
        draw,
        (CENTER, CENTER),
        ring_outer_r=SIZE * 0.20,
        ring_stroke=int(SIZE * 0.062),
        accent_r=SIZE * 0.05,
        accent_offset_angle_deg=-38,
    )
    img.save("assets/icon/icon_foreground.png")


def build_adaptive_background():
    img = radial_gradient_background(SIZE)
    img.save("assets/icon/icon_background.png")


if __name__ == "__main__":
    build_full_icon()
    build_foreground()
    build_adaptive_background()
    print("done")
