'use client';

import clsx from 'clsx';
import { useContext, useEffect, useState } from 'react';
import { Product } from 'lib/ecwid/types';
import { CategoryContext } from './context';
import { ThreeItemGrid } from './grid/three-items';
import { Carousel } from './carousel';
import IntroContents from 'components/intro/intro-contents';

export function Products({ category, products }: { category?: string; products?: Product[] }) {
    const { setCategory } = useContext(CategoryContext);
    const [intro, setIntro] = useState(true);

    useEffect(() => {
        setCategory(category);
    }, [setCategory, category]);

    const closeIntro = () => setIntro(false);

    return (
        <>
            <section className="grid grid-cols-6 grid-rows-1 max-w-screen-2xl gap-4 px-4 pb-4 ">
                {intro && (
                    <div className="col-span-2 h-full px-4 pb-4">
                        <IntroContents close={closeIntro} />
                    </div>
                )}
                <div className={clsx(intro ? 'col-span-4' : 'col-span-6', 'h-full px-4 pb-4')}>
                    <ThreeItemGrid products={products} />
                </div>
            </section>
            <Carousel products={products} />
        </>
    );
}
