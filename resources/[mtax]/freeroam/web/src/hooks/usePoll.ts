import { useEffect, useState } from 'react';
import { fetchNui } from '../utils/fetchNui';
import { isEnvBrowser } from '../utils/misc';

/** Asks the client script for `name` every `interval` ms while the calling window is open. */
export const usePoll = <T,>(name: string, interval: number, mock: T, body?: unknown): T | null => {
  const [data, setData] = useState<T | null>(isEnvBrowser() ? mock : null);
  const payload = JSON.stringify(body ?? {});

  useEffect(() => {
    let alive = true;
    let timer = 0;

    const run = () => {
      fetchNui<T>(name, JSON.parse(payload), mock)
        .then((reply) => {
          if (alive && reply) setData(reply);
        })
        .finally(() => {
          if (alive) timer = window.setTimeout(run, interval);
        });
    };

    run();
    return () => {
      alive = false;
      window.clearTimeout(timer);
    };
    // The mock is only a browser fallback and must not restart the loop.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [name, interval, payload]);

  return data;
};
