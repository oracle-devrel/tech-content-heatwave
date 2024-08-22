'use client';

import { CategoryContext, LocaleContext } from 'components/context';
import { Locale } from 'components/locale';
import { ReactNode, useState } from 'react';

export default function ContextProviders({ locale, children }: Locale & { children: ReactNode }) {
    const [category, setCategory] = useState<string | undefined>(undefined);

    return (
        <CategoryContext.Provider value={{ category, setCategory }}>
            <LocaleContext.Provider value={locale}>{children}</LocaleContext.Provider>
        </CategoryContext.Provider>
    );
}
