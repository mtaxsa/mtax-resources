// Will return whether the current environment is in a regular browser
// and not the MTAX NUI browser (GetParentResourceName only exists in-game)
export const isEnvBrowser = (): boolean => !(window as any).GetParentResourceName

// Basic no operation function
export const noop = () => {}