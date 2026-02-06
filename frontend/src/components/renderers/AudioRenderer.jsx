import { useState, useEffect, useRef } from 'react';
import YouTube from 'react-youtube';

function AudioRenderer({ question }) {
  const { media, anti_spoiler } = question;
  const [isPlaying, setIsPlaying] = useState(false);
  const [replaysLeft, setReplaysLeft] = useState(anti_spoiler?.max_replays || 3);
  const [timeLeft, setTimeLeft] = useState(0);
  const playerRef = useRef(null);
  const timerRef = useRef(null);
  const timeoutRef = useRef(null);

  // Reset state when question changes
  useEffect(() => {
    setIsPlaying(false);
    setReplaysLeft(anti_spoiler?.max_replays || 3);
    setTimeLeft(0);
    
    // Stop any playing audio from previous question
    if (playerRef.current) {
      try {
        playerRef.current.pauseVideo();
      } catch (e) {
        // Ignore errors if player isn't ready
      }
    }
  }, [question.id, anti_spoiler?.max_replays]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (timerRef.current) {
        clearInterval(timerRef.current);
      }
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }
      if (playerRef.current) {
        try {
          playerRef.current.pauseVideo();
        } catch (e) {
          // Ignore errors if player isn't ready
        }
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

      // Clear any existing timers
      if (timerRef.current) {
        clearInterval(timerRef.current);
      }
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }

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
      timeoutRef.current = setTimeout(() => {
        if (playerRef.current) {
          playerRef.current.pauseVideo();
        }
      }, duration * 1000);
    } else if (event.data === 2 || event.data === 0) {
      setIsPlaying(false);
      if (timerRef.current) {
        clearInterval(timerRef.current);
        timerRef.current = null;
      }
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
        timeoutRef.current = null;
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
      timerRef.current = null;
    }
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
      timeoutRef.current = null;
    }
  };

  const opts = {
    height: '0',
    width: '0',
    playerVars: {
      autoplay: 0,
      controls: 0,
      disablekb: 1,
      fs: 0,
      modestbranding: 1,
      start: media.start_sec,
      end: media.end_sec,
    },
  };

  return (
    <div className="text-center py-12">
      <div className="mb-8">
        <div className="w-48 h-48 mx-auto bg-gradient-to-br from-purple-600 to-pink-600 rounded-full flex items-center justify-center shadow-2xl animate-pulse">
          <svg 
            className="w-24 h-24 text-white" 
            fill="currentColor" 
            viewBox="0 0 20 20"
          >
            <path d="M18 3a1 1 0 00-1.196-.98l-10 2A1 1 0 006 5v9.114A4.369 4.369 0 005 14c-1.657 0-3 .895-3 2s1.343 2 3 2 3-.895 3-2V7.82l8-1.6v5.894A4.37 4.37 0 0015 12c-1.657 0-3 .895-3 2s1.343 2 3 2 3-.895 3-2V3z" />
          </svg>
        </div>
      </div>

      <YouTube
        videoId={media.video_id}
        opts={opts}
        onReady={onReady}
        onStateChange={onStateChange}
      />

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

export default AudioRenderer;
