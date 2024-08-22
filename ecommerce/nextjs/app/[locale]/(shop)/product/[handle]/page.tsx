import { getProduct } from 'lib/ecwid';
import { Locale } from 'components/locale';
import Product from './product';
import { ProductReviewSummary } from 'components/product/review-summary';

export const runtime = 'edge';

export default async function ProductPage({ params }: { params: { handle: string } & Locale }) {
    const product = await getProduct(params.handle);

    return (
        <div className="mx-auto max-w-screen-2xl px-4">
            <Product
                product={product}
                reviewSummary={
                    <ProductReviewSummary
                        locale={params.locale}
                        id={product?.handle}
                    />
                }
                locale={params.locale}
            />
        </div>
    );
}
