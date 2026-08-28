import { isEnvBrowser } from './misc';

/**
 * Simple wrapper around fetch API tailored for MTAX NUI use.
 *
 * MTAX serves the NUI page at the `nui://<resource>/...` origin, and the
 * client script exposes callbacks via `registerNuiCallback(name, handler)`.
 * The page reaches those handlers with a same-origin POST to `/<name>` (no
 * resource name / host needed, unlike FiveM's `https://resource/event`).
 *
 * @param eventName - The registerNuiCallback name to target
 * @param data - Data you wish to send in the NUI callback
 * @param mockData - Mock data to be returned if in the browser
 *
 * @return returnData - A promise for the data sent back by the callback's `cb` argument
 */

export async function fetchNui<T = any>(eventName: string, data?: any, mockData?: T): Promise<T> {
  const options = {
    method: 'post',
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: JSON.stringify(data ?? {}),
  };

  if (isEnvBrowser() && mockData !== undefined) return mockData;

  const resp = await fetch(`/${eventName}`, options);

  if (!resp.ok) {
    throw new Error(`fetchNui: ${eventName} failed with status ${resp.status}`);
  }

  const respFormatted = await resp.json();

  return respFormatted;
}
