# Browser input checks

The PR #25 captures came from commit `a5298f1`. They use the
release web build in headless Chromium on Linux ARM64. The browser used a fake
microphone and a virtual ALSA MIDI keyboard; no physical instrument was tested.

## Microphone

A synthetic C4-to-C5 scale at 80 BPM played through Chromium's fake microphone.
Four runs matched 13, 14, 7, and 15 of 16 notes. The [result screen](web-mic-results.png)
shows the 15-note run. The [console log](web-mic-console.jsonl) records
`getUserMedia` opening, the 44.1 kHz recorder starting and stopping, and four
WebGL GPU-stall warnings. It contains no browser console errors. That run had
14 long main-thread tasks totaling 1,956 ms in the first six seconds after Play.

## MIDI

Settings found the virtual keyboard, connected to it, and stage 1 matched all
16 notes. The [recording](web-midi-stage1.mp4) shows the scan, connection, and
practice flow. The [result screen](web-midi-results.png) shows 16 of 16 notes
matched.

These runs verify the browser input paths with synthetic devices. A real piano
microphone, USB keyboard, and Bluetooth keyboard still need device tests. The
microphone run has a screenshot and console log; recording it on the loaded
software-rendered host reduced the score to 1 of 16, so no microphone video is
included.

## Production MIDI-only startup, 2026-10-26

Production commit `fe561fc` opened the stage 1 practice screen at
`https://piano-tool.vercel.app/app/#/practice/stage_1` with a saved MIDI-only
preference. The check made `getUserMedia` reject if called. The Play button
appeared, and the browser made zero microphone requests. The app route returned
HTTP 200 with no page or console errors. Headless Chromium reported four GPU
readback stalls from software rendering.

The [production screenshot](production-midi-only.png) shows the idle practice
screen. No notes were played in this check. Physical microphone and MIDI input
remain unverified because no instrument was available.
