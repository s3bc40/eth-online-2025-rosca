export function Logo() {
  return (
    <div className="flex items-center gap-2">
      {/* Logo Icon */}
      <svg
        width="40"
        height="40"
        viewBox="0 0 200 200"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className="drop-shadow-md"
      >
        {/* Outer rotating circle */}
        <circle
          cx="100"
          cy="100"
          r="85"
          stroke="url(#gradient1)"
          strokeWidth="3"
          strokeDasharray="8 8"
          fill="none"
          opacity="0.6"
        />
        {/* Middle circle */}
        <circle
          cx="100"
          cy="100"
          r="65"
          stroke="url(#gradient2)"
          strokeWidth="2.5"
          fill="none"
          opacity="0.7"
        />
        {/* Inner circle background */}
        <circle
          cx="100"
          cy="100"
          r="45"
          fill="url(#gradient3)"
          opacity="0.15"
        />
        {/* Community nodes - positioned in a circle */}
        <g
          className="animate-[spin_20s_linear_infinite]"
          style={{ transformOrigin: "100px 100px" }}
        >
          {/* Node 1 - Top */}
          <circle cx="100" cy="35" r="8" fill="url(#nodeGradient)" />
          <circle cx="100" cy="35" r="5" fill="#ffffff" opacity="0.9" />

          {/* Node 2 - Right */}
          <circle cx="156" cy="75" r="8" fill="url(#nodeGradient)" />
          <circle cx="156" cy="75" r="5" fill="#ffffff" opacity="0.9" />

          {/* Node 3 - Bottom Right */}
          <circle cx="156" cy="125" r="8" fill="url(#nodeGradient)" />
          <circle cx="156" cy="125" r="5" fill="#ffffff" opacity="0.9" />

          {/* Node 4 - Bottom */}
          <circle cx="100" cy="165" r="8" fill="url(#nodeGradient)" />
          <circle cx="100" cy="165" r="5" fill="#ffffff" opacity="0.9" />

          {/* Node 5 - Bottom Left */}
          <circle cx="44" cy="125" r="8" fill="url(#nodeGradient)" />
          <circle cx="44" cy="125" r="5" fill="#ffffff" opacity="0.9" />

          {/* Node 6 - Left */}
          <circle cx="44" cy="75" r="8" fill="url(#nodeGradient)" />
          <circle cx="44" cy="75" r="5" fill="#ffffff" opacity="0.9" />
        </g>

        {/* Connection lines */}
        <g opacity="0.3" stroke="url(#gradient1)" strokeWidth="1.5">
          <line x1="100" y1="35" x2="156" y2="75" />
          <line x1="156" y1="75" x2="156" y2="125" />
          <line x1="156" y1="125" x2="100" y2="165" />
          <line x1="100" y1="165" x2="44" y2="125" />
          <line x1="44" y1="125" x2="44" y2="75" />
          <line x1="44" y1="75" x2="100" y2="35" />
        </g>
        {/* Center symbol - Dollar/Coin */}
        <g>
          <circle cx="100" cy="100" r="25" fill="url(#centerGradient)" />
          <text
            x="100"
            y="100"
            textAnchor="middle"
            dominantBaseline="central"
            fill="#ffffff"
            fontSize="20"
            fontWeight="700"
            fontFamily="system-ui, -apple-system, sans-serif"
          >
            $
          </text>
        </g>

        {/* Rotating arrows */}
        <g
          className="animate-[spin_15s_linear_infinite_reverse]"
          style={{ transformOrigin: "100px 100px" }}
          opacity="0.6"
        >
          <path
            d="M 145 100 Q 145 85 130 85 L 120 85 L 125 80 L 125 90 L 120 85"
            stroke="url(#gradient2)"
            strokeWidth="2.5"
            fill="none"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <path
            d="M 55 100 Q 55 115 70 115 L 80 115 L 75 120 L 75 110 L 80 115"
            stroke="url(#gradient2)"
            strokeWidth="2.5"
            fill="none"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </g>

        {/* Gradients */}
        <defs>
          <linearGradient id="gradient1" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#6366f1" />
            <stop offset="50%" stopColor="#8b5cf6" />
            <stop offset="100%" stopColor="#d946ef" />
          </linearGradient>

          <linearGradient id="gradient2" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#3b82f6" />
            <stop offset="100%" stopColor="#6366f1" />
          </linearGradient>

          <linearGradient id="gradient3" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#6366f1" />
            <stop offset="100%" stopColor="#8b5cf6" />
          </linearGradient>

          <linearGradient
            id="centerGradient"
            x1="0%"
            y1="0%"
            x2="100%"
            y2="100%"
          >
            <stop offset="0%" stopColor="#6366f1" />
            <stop offset="50%" stopColor="#8b5cf6" />
            <stop offset="100%" stopColor="#d946ef" />
          </linearGradient>
        </defs>
      </svg>

      <div className="flex flex-col items-start">
        <h1 className="text-xl tracking-tight bg-gradient-to-r from-indigo-500 via-purple-500 to-fuchsia-500 bg-clip-text text-transparent">
          ROSCA
        </h1>
        <div className="flex items-center gap-2">
          <div className="h-px w-2 bg-gradient-to-r from-transparent via-purple-500 to-transparent"></div>
          <span className="text-[8px] tracking-[0.3em] text-muted-foreground uppercase">
            Dapp
          </span>
          <div className="h-px w-2 bg-gradient-to-r from-transparent via-purple-500 to-transparent"></div>
        </div>
      </div>
    </div>
  );
}
