import { LocaleContext } from 'components/context';
import { GridTileImage } from 'components/grid/tile';
import type { Product } from 'lib/ecwid/types';
import Link from 'next/link';
import { useContext } from 'react';

function ThreeItemGridItem({
    locale,
    item,
    size,
    priority,
}: {
    locale: string;
    item: Product;
    size: 'full' | 'half';
    priority?: boolean;
}) {
    return (
        <div
            className={
                size === 'full' ? 'md:col-span-4 md:row-span-2' : 'md:col-span-2 md:row-span-1'
            }
        >
            <Link
                href={`${locale}/product/${item.handle}`}
                className="relative block aspect-square h-full w-full"
            >
                <GridTileImage
                    src={item.featuredImage?.url}
                    fill
                    sizes={
                        size === 'full'
                            ? '(min-width: 768px) 66vw, 100vw'
                            : '(min-width: 768px) 33vw, 100vw'
                    }
                    priority={priority}
                    alt={item.title}
                    label={{
                        position: size === 'full' ? 'center' : 'bottom',
                        title: item.title as string,
                        amount: item.priceRange.maxVariantPrice.amount,
                        currencyCode: item.priceRange.maxVariantPrice.currencyCode,
                    }}
                />
            </Link>
        </div>
    );
}

export function ThreeItemGrid({ products }: { products: Product[] | undefined }) {
    const locale = useContext(LocaleContext);

    const homepageItems = products;
    if (!homepageItems) return;

    if (!homepageItems[0] || !homepageItems[1] || !homepageItems[2]) return null;

    const [firstProduct, secondProduct, thirdProduct] = homepageItems;

    return (
        <section className="mx-auto grid h-full max-w-screen-2xl gap-4 md:grid-cols-6 md:grid-rows-2">
            <ThreeItemGridItem
                locale={locale}
                size="full"
                item={firstProduct}
                priority={true}
            />
            <ThreeItemGridItem
                locale={locale}
                size="half"
                item={secondProduct}
                priority={true}
            />
            <ThreeItemGridItem
                locale={locale}
                size="half"
                item={thirdProduct}
            />
        </section>
    );
}
