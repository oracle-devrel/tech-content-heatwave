import clsx from 'clsx';
import { ReactNode } from 'react';

const colors = {
    blue: 'bg-blue-100 text-blue-800 text-xs font-medium me-2 px-2.5 py-0.5 rounded-full dark:bg-blue-900 dark:text-blue-300',
    gray: 'bg-gray-100 text-gray-800 text-xs font-medium me-2 px-2.5 py-0.5 rounded-full dark:bg-gray-700 dark:text-gray-300',
} as const;

export function Pill({
    color = 'blue',
    children,
}: {
    color?: keyof typeof colors;
    children: ReactNode;
}) {
    const pill = colors[color];
    return <span className={clsx(pill, 'ml-2')}>{children}</span>;
}
