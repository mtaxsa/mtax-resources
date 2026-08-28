// Will return whether the current environment is in a regular browser
// and not the MTAX NUI browser (NUI pages are served from the nui:// origin)
export const isEnvBrowser = (): boolean => !window.location.href.startsWith('nui://')

// Basic no operation function
export const noop = () => {}