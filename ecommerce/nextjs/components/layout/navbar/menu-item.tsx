'use client';

import clsx from 'clsx';
import Link from 'next/link';
import { ReactNode } from 'react';

export default function MenuItem({
    path,
    selected,
    children,
}: {
    path: string;
    query?: { [key: string]: string };
    selected?: boolean;
    replace?: boolean;
    locale?: string;
    children: ReactNode;
}) {
    return (
        <Link
            href={path}
            locale={'en'}
            className={clsx(
                selected && 'underline',
                'text-neutral-500 underline-offset-4 hover:text-black hover:underline dark:text-neutral-400 dark:hover:text-neutral-300'
            )}
        >
            {children}
        </Link>
    );
}
