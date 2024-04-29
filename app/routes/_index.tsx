import type { MetaFunction } from "@remix-run/node"

export const meta: MetaFunction = () => {
  return [
    { title: "status.yamad.me" },
    { name: "description", content: "The Status of YamaD" },
  ]
}

const Section = ({
  summary,
  children,
}: { summary: string; children: React.ReactNode }) => (
  <details open className="mt-6 border-neutral-400 border-t px-4">
    <summary className="-translate-y-1/2 -mb-3.5 relative left-2 w-fit cursor-pointer select-none rounded-lg border border-neutral-400 bg-white px-4 py-1.5 font-bold">
      {summary}
    </summary>
    {children}
  </details>
)

export default function Index() {
  return (
    <>
      <Section summary="load average">かきくけこ</Section>
      <Section summary="now playing">あいうえお</Section>
    </>
  )
}
