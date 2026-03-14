"""
Like This — B&W 필터 썸네일 생성기
베이스: MoodFilm/assets/thumbnails/ 에서 필터별로 다른 사진 사용
출력: assets/thumbnails/bw_*.jpg (300×400, 3:4 portrait)
"""

from PIL import Image, ImageFilter
import numpy as np
import os

SRC_DIR = "/Users/kjmoon/MoodFilm/assets/thumbnails"
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "thumbnails")
THUMB_W, THUMB_H = 300, 400   # 3:4 portrait
QUALITY = 88

# 필터별 원본 이미지 매핑 — 분위기에 맞는 사진 분배
SOURCES = {
    "bw_pure":      "retro_ccd.jpg",    # 깨끗하고 화사한 인물
    "bw_noir":      "retro_ccd.jpg",     # Pure This와 동일 인물, 느와르 필터
    "bw_soft":      "film98.jpg",        # 2000s BY2K와 동일 인물, 소프트 필터
    "bw_2k":        "film98.jpg",       # 2000년대 필름 감성
    "bw_dust":      "vivid.jpg",         # Silver Glow와 동일 인물, 먼지 필터
    "bw_glow":      "vivid.jpg",        # 광택 있는 하이라이트
    "bw_paper":     "milk.jpg",          # Porcelain과 동일 인물, 종이 질감 필터
    "bw_porcelain": "milk.jpg",         # 밝고 매끈한 피부 표현
    "bw_silky":     "soft_pink.jpg",    # 셀카용 부드러운 인물
}


def load_source(filename: str) -> np.ndarray:
    path = os.path.join(SRC_DIR, filename)
    img = Image.open(path).convert("RGB")
    w, h = img.size
    target_h = int(w * 4 / 3)
    if target_h <= h:
        top = (h - target_h) // 2
        img = img.crop((0, top, w, top + target_h))
    else:
        target_w = int(h * 3 / 4)
        left = (w - target_w) // 2
        img = img.crop((left, 0, left + target_w, h))
    img = img.resize((THUMB_W, THUMB_H), Image.LANCZOS)
    return np.array(img, dtype=np.float32)


def to_bw(arr: np.ndarray) -> np.ndarray:
    """Rec 601 luminance B&W 변환"""
    lum = arr[:, :, 0] * 0.299 + arr[:, :, 1] * 0.587 + arr[:, :, 2] * 0.114
    return np.stack([lum, lum, lum], axis=2)


def apply_gamma(arr: np.ndarray, gamma: float) -> np.ndarray:
    arr = np.clip(arr / 255.0, 0, 1)
    return np.clip(arr ** (1.0 / gamma), 0, 1) * 255.0


def s_curve(arr: np.ndarray, strength: float = 1.0) -> np.ndarray:
    x = np.clip(arr / 255.0, 0, 1)
    curved = 0.5 + (x - 0.5) * (1.0 + strength * 0.8)
    return np.clip(curved, 0, 1) * 255.0


def lift_shadows(arr: np.ndarray, lift: float = 30.0) -> np.ndarray:
    return np.clip(arr + lift, 0, 255)


def compress_range(arr: np.ndarray, lo: float = 0.1, hi: float = 0.9) -> np.ndarray:
    x = np.clip(arr / 255.0, 0, 1)
    return np.clip(lo + x * (hi - lo), 0, 1) * 255.0


def add_grain(arr: np.ndarray, amount: float = 12.0) -> np.ndarray:
    noise = np.random.normal(0, amount, arr.shape).astype(np.float32)
    return np.clip(arr + noise, 0, 255)


def add_vignette(arr: np.ndarray, strength: float = 0.35) -> np.ndarray:
    h, w = arr.shape[:2]
    y, x = np.mgrid[0:h, 0:w].astype(np.float32)
    cx, cy = w / 2, h / 2
    dist = np.sqrt(((x - cx) / (w * 0.6)) ** 2 + ((y - cy) / (h * 0.6)) ** 2)
    mask = 1.0 - np.clip(dist * strength, 0, 1) ** 1.5
    return np.clip(arr * mask[:, :, np.newaxis], 0, 255)


def warm_tint(arr: np.ndarray, r_add: float = 8.0, b_sub: float = 10.0) -> np.ndarray:
    result = arr.copy()
    result[:, :, 0] = np.clip(arr[:, :, 0] + r_add, 0, 255)
    result[:, :, 2] = np.clip(arr[:, :, 2] - b_sub, 0, 255)
    return result


def glow_highlight(arr: np.ndarray, strength: float = 0.25) -> np.ndarray:
    pil = Image.fromarray(arr.astype(np.uint8))
    blurred = pil.filter(ImageFilter.GaussianBlur(radius=3))
    b_arr = np.array(blurred).astype(np.float32)
    screen = 255.0 - (255.0 - arr) * (255.0 - b_arr) / 255.0
    return np.clip(arr * (1 - strength) + screen * strength, 0, 255)


# ── 필터 정의 ─────────────────────────────────────────────────────────────────
FILTERS = {
    "bw_pure":      lambda a: apply_gamma(to_bw(a), 0.88),
    "bw_noir":      lambda a: add_vignette(s_curve(to_bw(a), 1.0), 0.5),
    "bw_soft":      lambda a: compress_range(apply_gamma(to_bw(a), 1.0), lo=0.08, hi=0.88),
    "bw_2k":        lambda a: compress_range(apply_gamma(to_bw(a), 1.0), lo=0.05, hi=0.85),
    "bw_dust":      lambda a: add_grain(lift_shadows(apply_gamma(to_bw(a), 1.05), lift=20), amount=9),
    "bw_glow":      lambda a: glow_highlight(apply_gamma(to_bw(a), 0.82), strength=0.3),
    "bw_paper":     lambda a: warm_tint(add_vignette(apply_gamma(to_bw(a), 0.9), 0.3), r_add=10, b_sub=12),
    "bw_porcelain": lambda a: apply_gamma(compress_range(to_bw(a), lo=0.05, hi=0.95), 0.78),
    "bw_silky":     lambda a: compress_range(apply_gamma(to_bw(a), 0.92), lo=0.06, hi=0.86),
}


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    print(f"출력 디렉토리: {OUT_DIR}\n")

    for fid, fn in FILTERS.items():
        src_file = SOURCES[fid]
        src_path = os.path.join(SRC_DIR, src_file)
        if not os.path.exists(src_path):
            print(f"  [SKIP] {fid} — 소스 없음: {src_file}")
            continue

        base = load_source(src_file)
        result = fn(base)
        img = Image.fromarray(result.astype(np.uint8))
        out_path = os.path.join(OUT_DIR, f"{fid}.jpg")
        img.save(out_path, "JPEG", quality=QUALITY, optimize=True)
        size_kb = os.path.getsize(out_path) / 1024
        print(f"  {fid}.jpg ← {src_file} → {size_kb:.1f} KB")

    print(f"\n완료: {len(FILTERS)}개 썸네일 → {OUT_DIR}")


if __name__ == "__main__":
    main()
