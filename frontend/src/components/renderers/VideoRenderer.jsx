import { useState, useEffect, useRef } from 'react';
import YouTube from 'react-youtube';

function VideoRenderer({ question }) {
  const { media, anti_spoiler } = question;
  const [isPlaying, setIsPlaying] = useState(false);
  const [replaysLeft, setReplaysLeft] = useState(anti_spoiler?.max_replays || 3);
  const [timeLeft, setTimeLeft] = useState(0);
  const playerRef = useRef(null);
  const timerRef = useRef(null);

  useEffect(() => {
    return () => {
      if (timerRef.current) {
        clearInterval(timerRef.current);
      }
    };
  }, []);

  const onReady = (event) => {
    playerRef.current = event.target;
  };

  const onStateChange = (event) => {
    // YouTube player state: 1 = playing, 2 = paused, 0 = ended
    if (event.data === 1) {
      setIsPlaying(true);
      const duration = media.end_sec - media.start_sec;
      setTimeLeft(duration);

      // Start countdown timer
      if (anti_spoiler?.auto_stop) {
        timerRef.current = setInterval(() => {
          setTimeLeft((prev) => {
            if (prev <= 1) {
              handleStop();
              return 0;
            }
            return prev - 1;
          });
        }, 1000);
      }

      // Auto-stop at end_sec
      setTimeout(() => {
        if (playerRef.current) {
          playerRef.current.pauseVideo();
        }
      }, duration * 1000);
    } else if (event.data === 2 || event.data === 0) {
      setIsPlaying(false);
      if (timerRef.current) {
        clearInterval(timerRef.current);
      }
    }
  };

  const handlePlay = () => {
    if (replaysLeft > 0 && playerRef.current) {
      playerRef.current.seekTo(media.start_sec);
      playerRef.current.playVideo();
      setReplaysLeft(replaysLeft - 1);
    }
  };

  const handleStop = () => {
    if (playerRef.current) {
      playerRef.current.pauseVideo();
    }
    setIsPlaying(false);
    if (timerRef.current) {
      clearInterval(timerRef.current);
    }
  };

  const opts = {
    height: '480',
    width: '854',
    playerVars: {
      autoplay: 0,
      controls: 1,
      disablekb: 0,
      fs: 1,
      modestbranding: anti_spoiler?.hide_titles ? 1 : 0,
      start: media.start_sec,
      end: media.end_sec,
    },
  };

  return (
    <div className="text-center py-8">
      <div className="mb-6 flex justify-center">
        <div className="rounded-lg overflow-hidden shadow-2xl">
          <YouTube
            videoId={media.video_id}
            opts={opts}
            onReady={onReady}
            onStateChange={onStateChange}
          />
        </div>
      </div>

      <div className="flex gap-4 justify-center items-center">
        <button
          onClick={handlePlay}
          disabled={replaysLeft === 0 || isPlaying}
          className="px-8 py-4 bg-green-500 hover:bg-green-600 disabled:bg-gray-500 disabled:cursor-not-allowed text-white font-bold rounded-lg text-xl transition-colors"
        >
          {isPlaying ? 'Playing...' : 'Play'}
        </button>
        <button
          onClick={handleStop}
          disabled={!isPlaying}
          className="px-8 py-4 bg-red-500 hover:bg-red-600 disabled:bg-gray-500 disabled:cursor-not-allowed text-white font-bold rounded-lg text-xl transition-colors"
        >
          Stop
        </button>
      </div>

      <div className="mt-6 text-gray-300">
        {anti_spoiler?.max_replays && (
          <div className="text-xl">
            Replays left: <span className="font-bold text-yellow-400">{replaysLeft}</span>
          </div>
        )}
        {anti_spoiler?.auto_stop && timeLeft > 0 && (
          <div className="text-xl mt-2">
            Time left: <span className="font-bold text-blue-400">{timeLeft}s</span>
          </div>
        )}
      </div>
    </div>
  );
}

export default VideoRenderer;
