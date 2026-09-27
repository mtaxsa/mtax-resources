export const isEnvBrowser = (): boolean => !(window as any).GetParentResourceName

export const noop = () => {}

export const clamp = (value: number, low: number, high: number) => Math.min(Math.max(value, low), high)
