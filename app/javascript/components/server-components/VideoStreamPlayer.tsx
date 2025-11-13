import throttle from "lodash/throttle";
import * as React from "react";
import { createCast } from "ts-safe-cast";

import { createConsumptionEvent } from "$app/data/consumption_analytics";
import { trackMediaLocationChanged } from "$app/data/media_location";
import GuidGenerator from "$app/utils/guid_generator";
import { createJWPlayer } from "$app/utils/jwPlayer";
import { register } from "$app/utils/serverComponentUtil";

import { TranscodingNoticeModal } from "$app/components/Download/TranscodingNoticeModal";
import { useRunOnce } from "$app/components/useRunOnce";

const LOCATION_TRACK_EVENT_DELAY_MS = 10_000;
const VISUAL_QUALITY_DEBOUNCE_MS = 500; // Prevent rapid repeated seeks

type SubtitleFile = {
  file: string;
  label: string;
  kind: "captions";
};

type Video = {
  sources: string[];
  guid: string;
  title: string;
  tracks: SubtitleFile[];
  external_id: string;
  latest_media_location: { location: number } | null;
  content_length: number | null;
};

const fakeVideoUrlGuidForObfuscation = "ef64f2fef0d6c776a337050020423fc0";

export const VideoStreamPlayer = ({
  playlist: initialPlaylist,
  index_to_play,
  url_redirect_id,
  purchase_id,
  should_show_transcoding_notice,
  transcode_on_first_sale,
}: {
  playlist: Video[];
  index_to_play: number;
  url_redirect_id: string;
  purchase_id: string | null;
  should_show_transcoding_notice: boolean;
  transcode_on_first_sale: boolean;
}) => {
  const containerRef = React.useRef<HTMLDivElement>(null);

  useRunOnce(() => {
    const createPlayer = async () => {
      if (!containerRef.current) return;

      const playerId = `video-player-${GuidGenerator.generate()}`;
      containerRef.current.id = playerId;

      let lastPlayedId: number | undefined;
      const initialSeekDoneByIndex = new Map<number, boolean>();
      let lastVisualQualityTimestamp = 0;
      const playlist = initialPlaylist;

      const player = await createJWPlayer(playerId, {
        width: "100%",
        height: "100%",
        playlist: playlist.map((video) => ({
          sources: video.sources.map((source) => ({
            file: source.replace(fakeVideoUrlGuidForObfuscation, video.guid),
          })),
          tracks: video.tracks,
          title: video.title,
        })),
      });

      const safeSeek = (targetPosition: number) => {
        try {
          const duration = player.getDuration();
          if (!duration || duration <= 0) {
            return;
          }

          const clampedPosition = Math.max(0, Math.min(targetPosition, duration - 0.25));

          player.seek(clampedPosition);
        } catch (_error) {}
      };

      const updateLocalMediaLocation = (position: number, duration: number) => {
        const playlistIndex = player.getPlaylistIndex();
        const videoFile = playlist[playlistIndex];

        if (videoFile && initialSeekDoneByIndex.get(playlistIndex) && lastPlayedId === playlistIndex) {
          const location = position === duration ? 0 : position;
          if (videoFile.latest_media_location == null) videoFile.latest_media_location = { location };
          else videoFile.latest_media_location.location = location;
        }
      };

      const trackMediaLocation = (position: number) => {
        if (purchase_id != null) {
          const videoFile = playlist[player.getPlaylistIndex()];
          if (!videoFile) return;
          void trackMediaLocationChanged({
            urlRedirectId: url_redirect_id,
            productFileId: videoFile.external_id,
            purchaseId: purchase_id,
            location:
              videoFile.content_length != null && position > videoFile.content_length
                ? videoFile.content_length
                : position,
          });
        }
      };

      const throttledTrackMediaLocation = throttle(trackMediaLocation, LOCATION_TRACK_EVENT_DELAY_MS);

      player.on("ready", () => {
        player.playlistItem(index_to_play);
      });

      player.on("seek", (ev) => {
        trackMediaLocation(ev.offset);
        updateLocalMediaLocation(ev.offset, player.getDuration());
      });

      player.on("time", (ev) => {
        throttledTrackMediaLocation(ev.position);
        updateLocalMediaLocation(ev.position, ev.duration);
      });

      player.on("complete", () => {
        throttledTrackMediaLocation.cancel();
        const videoFile = playlist[player.getPlaylistIndex()];
        if (!videoFile) return;
        trackMediaLocation(videoFile.content_length === null ? player.getDuration() : videoFile.content_length);
        updateLocalMediaLocation(player.getDuration(), player.getDuration());
      });

      player.on("play", () => {
        const itemId = player.getPlaylistIndex();
        const videoFile = playlist[itemId];
        if (videoFile !== undefined && lastPlayedId !== itemId) {
          void createConsumptionEvent({
            eventType: "watch",
            urlRedirectId: url_redirect_id,
            productFileId: videoFile.external_id,
            purchaseId: purchase_id,
          });
          lastPlayedId = itemId;
          initialSeekDoneByIndex.set(itemId, false);
        }
      });

      player.on("visualQuality", () => {
        const now = Date.now();
        const timeSinceLastCall = now - lastVisualQualityTimestamp;

        if (timeSinceLastCall < VISUAL_QUALITY_DEBOUNCE_MS) {
          return;
        }

        lastVisualQualityTimestamp = now;
        const playlistIndex = player.getPlaylistIndex();

        if (initialSeekDoneByIndex.get(playlistIndex)) {
          return;
        }

        const videoFile = playlist[playlistIndex];
        const savedLocation = videoFile?.latest_media_location?.location;

        if (videoFile && savedLocation != null && savedLocation !== videoFile.content_length && savedLocation > 0) {
          safeSeek(savedLocation);
        }

        initialSeekDoneByIndex.set(playlistIndex, true);
      });

      player.on("error", () => {});
    };

    void createPlayer();
  });

  return (
    <>
      {should_show_transcoding_notice ? (
        <TranscodingNoticeModal transcodeOnFirstSale={transcode_on_first_sale} />
      ) : null}
      <div ref={containerRef} className="absolute h-full w-full"></div>
    </>
  );
};

export default register({ component: VideoStreamPlayer, propParser: createCast() });
