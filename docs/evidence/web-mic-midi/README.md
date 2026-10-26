# Browser input checks for PR #25

These captures came from commit `a5298f1`, the head of PR #25. They use the
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
