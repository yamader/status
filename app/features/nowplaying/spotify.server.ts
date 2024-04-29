import {
  SPOTIFY_CLIENT_ID,
  SPOTIFY_CLIENT_SECRET,
  SPOTIFY_REFRESH_TOKEN,
} from "./constants.server"
import type { NowPlaying } from "./index.server"

type ArtistObject = {
  external_urls: {
    spotify: string
  }
  name: string
}

declare global {
  var _spotifyUserToken: { token: string; validfor: number }
}

async function getUserToken(refresh = false) {
  if (!refresh && globalThis._spotifyUserToken?.validfor - Date.now() > 60_000)
    return globalThis._spotifyUserToken.token

  const basic = Buffer.from(
    `${SPOTIFY_CLIENT_ID}:${SPOTIFY_CLIENT_SECRET}`,
  ).toString("base64")
  const res = await fetch("https://accounts.spotify.com/api/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      Authorization: `Basic ${basic}`,
    },
    body: new URLSearchParams({
      grant_type: "refresh_token",
      refresh_token: SPOTIFY_REFRESH_TOKEN,
    }),
  })
  if (!res.ok) {
    console.error(res)
    return null
  }

  const { access_token, expires_in } = await res.json()
  globalThis._spotifyUserToken = {
    token: access_token,
    validfor: Date.now() + expires_in * 1000,
  }
  return access_token
}

export async function getSpotifyNowPlaying(): Promise<NowPlaying | null> {
  const token = await getUserToken()
  if (!token) return null

  const res = await fetch(
    "https://api.spotify.com/v1/me/player/currently-playing",
    { headers: { Authorization: `Bearer ${token}` } },
  )
  if (!res.ok) {
    console.error(res)
    return null
  }

  const body = await res.text()
  if (!body) return null
  const {
    timestamp,
    progress_ms,
    item: { artists, duration_ms, external_urls, name },
  } = JSON.parse(body)
  return {
    timestamp,
    progress: progress_ms,
    duration: duration_ms,

    name,
    url: external_urls.spotify,
    artists: (artists as ArtistObject[]).map(e => ({
      name: e.name,
      url: e.external_urls.spotify,
    })),
  }
}
