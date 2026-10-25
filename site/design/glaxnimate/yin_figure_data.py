"""Static data for the D4 figure: a synthesized A4 (440 Hz, three decaying partials, as the
app's review tone) run through the same YIN steps as lib/audio/pitch_detector.dart.
Prints SVG path data for the buffer and the normalised difference curve."""
import json
import math

SR, N = 44100, 2048
HALF = N // 2
f = 440.0
sig = [0.5 * math.sin(2 * math.pi * f * i / SR) + 0.25 * math.sin(2 * math.pi * 2 * f * i / SR + 0.4)
       + 0.12 * math.sin(2 * math.pi * 3 * f * i / SR + 1.1) for i in range(N)]
diff = [0.0] * HALF
for tau in range(1, HALF):
    s = 0.0
    for i in range(HALF):
        d = sig[i] - sig[i + tau]
        s += d * d
    diff[tau] = s
cmnd = [1.0] * HALF
run = 0.0
for tau in range(1, HALF):
    run += diff[tau]
    cmnd[tau] = diff[tau] * tau / run
tau = 1
while tau < HALF:
    if cmnd[tau] < 0.1:
        while tau + 1 < HALF and cmnd[tau + 1] < cmnd[tau]:
            tau += 1
        break
    tau += 1
a, b, c = cmnd[tau - 1], cmnd[tau], cmnd[tau + 1]
better = tau + (a - c) / (2 * (a - 2 * b + c))
freq = SR / better
midi = round(69 + 12 * math.log2(freq / 440))

W, H = 600, 150
TAU_MAX = 400
YMAX = math.ceil(max(cmnd[1:TAU_MAX + 1]) * 2) / 2
def cmnd_path():
    pts = []
    for t in range(1, TAU_MAX + 1, 2):
        x = t / TAU_MAX * W
        y = H - cmnd[t] / YMAX * H
        pts.append(f'{x:.1f} {y:.1f}')
    return 'M' + ' L'.join(pts)
def wave_path():
    pts = []
    step = 12
    for i in range(0, N, step):
        x = i / (N - 1) * W
        y = 40 - sig[i] / 0.9 * 36
        pts.append(f'{x:.1f} {y:.1f}')
    return 'M' + ' L'.join(pts)
print(json.dumps({'tau': better, 'freq': freq, 'midi': midi,
                  'dip': [better / TAU_MAX * W, H - b / YMAX * H], 'ymax': YMAX, 'one_y': H - 1 / YMAX * H,
                  'threshold_y': H - 0.1 / YMAX * H, 'cmnd': cmnd_path(), 'wave': wave_path()}))
