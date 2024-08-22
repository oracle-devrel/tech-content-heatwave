import { Products } from 'components/products';
import { getProducts } from 'lib/ecwid';
import { Product } from 'lib/ecwid/types';

export const runtime = 'edge';

export const metadata = {
    description:
        'High-performance ecommerce store built with Next.js, Vercel, and Ecwid by Lightspeed.',
    openGraph: {
        type: 'website',
    },
};

export default async function HomePage({
    searchParams,
}: {
    searchParams?: {
        category?: string;
    };
}) {
    const products: Product[] | undefined = await getProducts({
        category: searchParams?.category,
    }).then(result => new Promise(resolve => setTimeout(() => resolve(result), 4000)));

    return (
        <Products
            category={searchParams?.category}
            products={products}
        />
    );
}
