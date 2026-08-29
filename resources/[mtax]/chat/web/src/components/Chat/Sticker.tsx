import React, { useState } from 'react';

const toChar = (id: string) =>
  id
    .split('-')
    .map((part) => String.fromCodePoint(parseInt(part, 16)))
    .join('');

interface Props {
  id: string;
  size: number;
  className?: string;
}

export const Sticker: React.FC<Props> = ({ id, size, className }) => {
  const [failed, setFailed] = useState(false);

  if (failed) {
    return (
      <span className={className} style={{ fontSize: size * 0.86, lineHeight: 1 }}>
        {toChar(id)}
      </span>
    );
  }

  return (
    <img
      src={`./stickers/${id}.svg`}
      alt=""
      width={size}
      height={size}
      draggable={false}
      onError={() => setFailed(true)}
      className={className}
      style={{ width: size, height: size }}
    />
  );
};
