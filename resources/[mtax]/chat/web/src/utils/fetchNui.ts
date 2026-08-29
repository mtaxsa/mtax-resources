import { isEnvBrowser } from './misc';

export async function fetchNui<T = any>(eventName: string, data?: any, mockData?: T): Promise<T> {
  if (isEnvBrowser()) return (mockData ?? ({} as T));

  const resourceName = (window as any).GetParentResourceName
    ? (window as any).GetParentResourceName()
    : 'chat';

  try {
    const response = await fetch(`nui://${resourceName}/${eventName}`, {
      method: 'post',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data ?? {}),
    });

    return await response.json();
  } catch {
    return {} as T;
  }
}
