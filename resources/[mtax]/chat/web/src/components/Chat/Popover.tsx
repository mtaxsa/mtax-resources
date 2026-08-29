import React, { useLayoutEffect, useRef, useState } from 'react';

interface Props {
  width: number;
  children: React.ReactNode;
}

interface Placement {
  below: boolean;
  max: number;
}

export const Popover: React.FC<Props> = ({ width, children }) => {
  const GAP = 8;
  const ref = useRef<HTMLDivElement>(null);
  const [placement, setPlacement] = useState<Placement>({ below: false, max: 0 });

  useLayoutEffect(() => {
    const node = ref.current;
    const host = node?.parentElement;
    if (!node || !host) return;

    const measure = () => {
      const anchor = host.getBoundingClientRect();
      const above = Math.max(0, anchor.top - GAP);
      const under = Math.max(0, window.innerHeight - anchor.bottom - GAP);

      const capped = node.style.maxHeight;
      node.style.maxHeight = 'none';
      const height = node.offsetHeight;
      node.style.maxHeight = capped;

      const below = height > above && under > above;
      const max = below ? under : above;

      setPlacement((current) =>
        current.below === below && current.max === max ? current : { below, max }
      );
    };

    measure();

    const observer = new ResizeObserver(measure);
    observer.observe(node);
    observer.observe(document.documentElement);
    window.addEventListener('resize', measure);

    return () => {
      observer.disconnect();
      window.removeEventListener('resize', measure);
    };
  }, []);

  return (
    <div
      ref={ref}
      className={`interactive absolute right-0 z-10 flex animate-[chatPopIn_0.14s_ease-out] flex-col overflow-hidden rounded-xl border border-line bg-panel-solid shadow-[0_10px_28px_rgb(0_0_0/0.45)] ${
        placement.below ? 'top-full mt-2' : 'bottom-full mb-2'
      }`}
      style={{ width, maxHeight: placement.max }}
    >
      {children}
    </div>
  );
};
