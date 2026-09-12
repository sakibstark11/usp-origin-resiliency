# Local CMAF origin-resiliency lab

This is a license-free local analogue of the AWS two-Region architecture. It has two independent encoder paths and one NGINX gateway/web player, without Unified Streaming Platform or separate origin containers.

```text
contribution (one 25-fps, fixed-GOP live feed)
     |                         |
 encoder-a -- volume-a --\\
                         gateway + web player :8080
 encoder-b -- volume-b --/
```

Each encoder produces fMP4 HLS: a CMAF-style `init.mp4`, `.m4s` fragments and an HLS playlist. The source GOP is fixed at 50 frames, the two output GOPs are also 50 frames, and HLS segments are 2 seconds. Thus IDRs and intended segment boundaries have the same cadence in both paths. Encoder A overlays `ENCODER A / PRIMARY` and Encoder B overlays `ENCODER B / BACKUP`, each with a UTC clock.

## Start

```bash
docker compose up -d
docker compose logs -f encoder-a encoder-b gateway
```

Compose pulls `jrottenberg/ffmpeg:7.1-alpine` (which includes FFmpeg's `drawtext` filter and DejaVu fonts) and runs every component, including the web player, in containers. No host web server or encoder installation is required.

The encoder containers start first and listen for the shared UDP feed. The contribution container sends to their fixed private Docker-network addresses (`172.30.0.11` and `172.30.0.12`), avoiding hostname resolution in the static FFmpeg image.

Wait about 10 seconds, then open the built-in player:

```text
http://localhost:8080/
```

The player uses hls.js (loaded from jsDelivr) where the browser lacks native HLS support. Direct streams are `http://localhost:8080/a/live.m3u8` and `http://localhost:8080/b/live.m3u8`. The convenience URL `http://localhost:8080/live.m3u8` serves A first, then B if the requested file is unavailable.

## Test encoder switching

```bash
docker compose stop encoder-a
docker compose logs -f encoder-a encoder-b gateway
```

The player attempts encoder B after a fatal HLS network error from A; it also has a **Switch to encoder B** button for an immediate visible test. Restore A with:

```bash
docker compose start encoder-a
```

## Inspect cadence

```bash
docker compose exec encoder-a cat /out/live.m3u8
docker compose exec encoder-b cat /out/live.m3u8
```

Every `#EXTINF` should be 2 seconds after the initial transient. Both playlists should contain `#EXT-X-INDEPENDENT-SEGMENTS`, fMP4 map references, and UTC-derived initial media sequence numbers.

## Scope

This simulates two independent encoders receiving one time-aligned contribution stream, fMP4 HLS packaging, and client-side switching. It does not implement MediaLive EPOCH_LOCKING or MediaPackage V2 CMAF Live Ingest/failover logic; FFmpeg HLS writes files rather than pushing DASH-IF Interface-1 fragments to a packager. Use it for cadence validation and visible switching drills, not as proof of frame-perfect production failover.

For a production-equivalent design, retain the invariant demonstrated here but replace the source with timecode/PTP-locked contribution feeds, configure MediaLive with embedded timecode and Epoch Locking, and ingest CMAF into two MediaPackage V2 endpoints.

## Gateway design

The gateway mounts both encoder output volumes directly and serves the fMP4 HLS files itself. This is intentionally simpler than the AWS packaging/origin layer. It is enough to validate encoding cadence, HLS playback, and visible A/B path switching, but it does not model independent MediaPackage-origin health or server-side media-aware origin failover.

## Reset

```bash
docker compose down -v
```
