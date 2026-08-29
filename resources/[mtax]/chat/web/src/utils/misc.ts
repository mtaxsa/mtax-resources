export const isEnvBrowser = (): boolean => !(window as any).GetParentResourceName

export const noop = () => {}