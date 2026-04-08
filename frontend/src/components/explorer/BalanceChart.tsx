/**
 * BalanceChart — SVG area chart for native token balance over time.
 *
 * Renders an inline SVG with a filled area and stroke line. No external
 * chart library dependency. Accepts balance history data points and
 * handles edge cases (empty data, single point, all-zero balances).
 *
 * @example
 *   <BalanceChart data={[{ timestamp: "2025-01-01T00:00:00Z", balance_wei: "1000000000000000000" }]} />
 */

interface BalanceChartProps {
  data: { timestamp: string; balance_wei: string }[]
}

const WIDTH = 800
const HEIGHT = 200
const PAD_X = 60
const PAD_Y = 20
const CHART_W = WIDTH - PAD_X * 2
const CHART_H = HEIGHT - PAD_Y * 2

export function BalanceChart({ data }: BalanceChartProps) {
  if (!data || data.length === 0) {
    return (
      <div className="flex items-center justify-center h-48 text-rex-text-secondary text-sm border border-rex-border rounded-lg">
        No balance history
      </div>
    )
  }

  let points = data.map(d => ({
    time: new Date(d.timestamp).getTime(),
    value: weiToNumber(d.balance_wei),
  }))

  // For sparse data (1-2 points), synthesize a start-from-zero point
  // so the chart shows the journey from 0 → current value
  if (points.length < 3) {
    const first = points[0]
    const padMs = 3600_000 // 1 hour of visual padding
    points = [
      { time: first.time - padMs, value: 0 },
      ...points,
    ]
  }

  const minTime = points[0].time
  const maxTime = points[points.length - 1].time
  const timeRange = maxTime - minTime || 1

  // Y axis always starts at 0 for intuitive magnitude
  const maxVal = Math.max(...points.map(p => p.value))
  const valRange = maxVal || 1

  const toX = (time: number) => PAD_X + ((time - minTime) / timeRange) * CHART_W
  const toY = (val: number) => PAD_Y + (1 - val / valRange) * CHART_H

  // Build SVG path
  const linePoints = points.map(p => `${toX(p.time).toFixed(1)},${toY(p.value).toFixed(1)}`)
  const linePath = `M${linePoints.join(' L')}`

  // Area: line path + close to bottom-right → bottom-left
  const areaPath = `${linePath} L${toX(points[points.length - 1].time).toFixed(1)},${(PAD_Y + CHART_H).toFixed(1)} L${PAD_X},${(PAD_Y + CHART_H).toFixed(1)} Z`

  // Axis labels — always 0 at bottom, max at top
  const yLabels = [
    { value: maxVal, y: toY(maxVal) },
    { value: 0, y: toY(0) },
  ]

  const xLabelCount = Math.min(points.length, 5)
  const xLabels = Array.from({ length: xLabelCount }, (_, i) => {
    const idx = Math.round((i / (xLabelCount - 1)) * (points.length - 1))
    const p = points[idx]
    return { time: p.time, x: toX(p.time) }
  })

  return (
    <div className="border border-rex-border rounded-lg p-4">
      <h2 className="text-lg font-semibold mb-3 text-rex-text">Balance History</h2>
      <svg viewBox={`0 0 ${WIDTH} ${HEIGHT + 20}`} className="w-full h-auto" preserveAspectRatio="xMidYMid meet">
        {/* Area fill */}
        <path d={areaPath} fill="var(--color-rex-primary)" opacity="0.1" />
        {/* Line stroke */}
        <path d={linePath} fill="none" stroke="var(--color-rex-primary)" strokeWidth="2" />

        {/* Y-axis labels */}
        {yLabels.map((l, i) => (
          <text key={i} x={PAD_X - 8} y={l.y + 4} textAnchor="end" className="fill-rex-text-secondary" fontSize="11" fontFamily="monospace">
            {formatChartValue(l.value)}
          </text>
        ))}

        {/* X-axis labels */}
        {xLabels.map((l, i) => (
          <text key={i} x={l.x} y={HEIGHT + 14} textAnchor="middle" className="fill-rex-text-secondary" fontSize="10">
            {formatChartDate(l.time)}
          </text>
        ))}

        {/* Baseline */}
        <line x1={PAD_X} y1={PAD_Y + CHART_H} x2={PAD_X + CHART_W} y2={PAD_Y + CHART_H} stroke="var(--color-rex-border)" strokeWidth="1" />
      </svg>
    </div>
  )
}

/** Convert wei string to a float (ETH-scale, 18 decimals) */
function weiToNumber(wei: string): number {
  try {
    const n = BigInt(wei)
    const whole = Number(n / BigInt(10 ** 18))
    const frac = Number(n % BigInt(10 ** 18)) / 10 ** 18
    return whole + frac
  } catch {
    return 0
  }
}

/** Format a number for the Y-axis label */
function formatChartValue(val: number): string {
  if (val >= 1_000_000) return `${(val / 1_000_000).toFixed(1)}M`
  if (val >= 1_000) return `${(val / 1_000).toFixed(1)}K`
  if (val >= 1) return val.toFixed(2)
  if (val > 0) return val.toFixed(4)
  return '0'
}

/** Format a timestamp for the X-axis label */
function formatChartDate(ms: number): string {
  const d = new Date(ms)
  return `${d.getMonth() + 1}/${d.getDate()}`
}
