import "@fontsource-variable/fira-code"
import type { LinksFunction } from "@remix-run/node"
import {
  Links,
  Meta,
  Outlet,
  Scripts,
  ScrollRestoration,
} from "@remix-run/react"
import stylesheet from "~/tailwind.css?url"
import { version } from "../package.json"

export const links: LinksFunction = () => [
  { rel: "stylesheet", href: stylesheet },
]

export function Layout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ja" className="font-mono">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width" />
        <Meta />
        <Links />
      </head>
      <body className="flex min-h-screen flex-col">
        {children}
        <ScrollRestoration />
        <Scripts />
      </body>
    </html>
  )
}

export default function App() {
  return (
    <>
      <header className="flex items-baseline gap-1">
        <h1 className="p-2 font-black text-xl">status.yamad.me</h1>
        <a
          href="https://github.com/yamader/status"
          className="font-bold text-neutral-500 text-sm hover:underline">
          v{version}
        </a>
      </header>
      <Outlet />
      <footer className="my-2 mt-auto text-center">
        <small className="font-bold font-xs">
          {`(c) ${new Date().getFullYear()} `}
          <a href="https://yamad.me" className="hover:underline">
            YamaD
          </a>
        </small>
      </footer>
    </>
  )
}
