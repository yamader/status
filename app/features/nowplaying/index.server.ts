import { getSpotifyNowPlaying } from "./spotify.server"

export type NowPlaying = {
  timestamp: number
  progress: number
  duration: number

  name: string
  url: string
  artists: {
    name: string
    url: string
  }[]
}

export async function getNowPlaying() {
  return Promise.any([getSpotifyNowPlaying()])
}
