# Local CMAF origin-resiliency lab

This is a license-free local analogue of the AWS two-Region architecture. It has two independent encoder paths and one NGINX gateway/web player, without Unified Streaming Platform or separate origin containers.

Each encoder produces fMP4 HLS: a CMAF-style `init.mp4`, `.m4s` fragments and an HLS playlist. The source GOP is fixed at 50 frames, the two output GOPs are also 50 frames, and HLS segments are 2 seconds. Thus IDRs and intended segment boundaries have the same cadence in both paths. Encoder A overlays `ENCODER A / PRIMARY` and Encoder B overlays `ENCODER B / BACKUP`, each with a UTC clock.

## Start

```bash
docker compose up -d
```

```text
http://localhost:8080/
```

The player uses hls.js (loaded from jsDelivr) where the browser lacks native HLS support. Direct streams are `http://localhost:8080/a/live.m3u8` and `http://localhost:8080/b/live.m3u8`. The convenience URL `http://localhost:8080/live.m3u8` serves A first, then B if the requested file is unavailable.

## Test encoder switching

```bash
docker compose stop encoder-a encoder-a
docker compose logs -f encoder-a encoder-b gateway
```

The player attempts encoder B after a fatal HLS network error from A; it also has a **Switch to encoder B** button for an immediate visible test. Restore A with:

```bash
docker compose start encoder-a encoder-a
```

<video src="./snap.mp4" width="320" height="240" controls></video>
