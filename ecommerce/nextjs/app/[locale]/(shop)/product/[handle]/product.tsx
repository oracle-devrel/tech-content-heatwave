'use client';

import { Image } from 'lib/ecwid/types';
import { Product } from 'lib/ecwid/types';
import { Locale } from 'components/locale';
import { Gallery } from 'components/product/gallery';
import { ProductDescription } from 'components/product/product-description';
import { CategoryContext } from 'components/context';
import { ReactNode, useContext, useEffect } from 'react';

export default function ProductView({
    product,
    reviewSummary,
}: { product?: Product; reviewSummary: ReactNode } & Locale) {
    const { setCategory } = useContext(CategoryContext);
    useEffect(() => {
        setCategory(product?.category);
    }, [setCategory, product?.category]);

    if (!product) return <div>Not found...</div>;

    const productJsonLd = {
        '@context': 'https://schema.org',
        '@type': 'Product',
        name: product.title,
        description: product.descriptions[0]?.description,
        image: product.featuredImage.url,
        offers: {
            '@type': 'AggregateOffer',
            availability: product.availableForSale
                ? 'https://schema.org/InStock'
                : 'https://schema.org/OutOfStock',
            priceCurrency: product.priceRange.minVariantPrice.currencyCode,
            highPrice: product.priceRange.maxVariantPrice.amount,
            lowPrice: product.priceRange.minVariantPrice.amount,
        },
    };

    return (
        <>
            <script
                type="application/ld+json"
                dangerouslySetInnerHTML={{
                    __html: JSON.stringify(productJsonLd),
                }}
            />
            <div className="flex flex-col rounded-lg border border-neutral-200 bg-white p-8 dark:border-neutral-800 dark:bg-black md:p-12 lg:flex-row lg:gap-8">
                <div className="h-full w-full basis-full lg:basis-4/6">
                    <Gallery
                        images={product.images.map((image: Image) => ({
                            src: image.url,
                            altText: image.altText || '',
                        }))}
                    />
                </div>

                <div className="basis-full lg:basis-2/6">
                    <ProductDescription
                        product={product}
                        reviewSummary={reviewSummary}
                    />
                </div>
            </div>
        </>
    );
}
