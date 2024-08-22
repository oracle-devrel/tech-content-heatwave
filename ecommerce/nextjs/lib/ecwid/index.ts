import {
    Cart,
    CartItem,
    Collection,
    EcwidCart,
    EcwidCartItem,
    EcwidCheckout,
    EcwidNode,
    EcwidOrder,
    EcwidPagedResult,
    Menu,
    Money,
    Product,
    StrapiProductCategory,
    StrapiCollection,
    StrapiProduct,
    StrapiItem,
    ReshapedStrapiItem,
    StrapiReview,
    Review,
    StrapiCustomer,
    Customer,
    ReviewSummary,
    StrapiReviewSummary,
    StrapiDescription,
    Description,
} from './types';

import { DEFAULT_CURRENCY_CODE, DEFAULT_OPTION, TAGS } from 'lib/constants';

import { revalidateTag } from 'next/cache';
import { cookies, headers } from 'next/headers';
import { NextRequest, NextResponse } from 'next/server';

const store_id = process.env.ECWID_STORE_ID!;

const endpoint = 'http://localhost:1337/api';

const currencyCode: string = DEFAULT_CURRENCY_CODE;

export async function strapiFetch<T>({
    method,
    path,
    query,
    cache,
    headers,
    tags,
    payload,
    revalidate,
}: {
    method: string;
    path: string;
    query?: Record<string, string | string[]>;
    headers?: HeadersInit;
    cache?: RequestCache;
    tags?: string[];
    payload?: any | undefined;
    revalidate?: number;
}): Promise<{ status: number; body: T } | never> {
    try {
        const options: RequestInit = {
            method: method,
            headers: {
                'Content-Type': 'application/json',
                ...headers,
            },
            cache: cache ?? 'no-store',
            ...(tags && { next: { tags: tags } }),
        };

        if (revalidate) {
            options.next = { ...options.next, ...{ revalidate: revalidate } };
        }

        if (payload) {
            options.body = JSON.stringify(payload);
        }

        const prefixedPath = path.startsWith('/') ? path : `/${path}`;
        let url = `${endpoint}${prefixedPath}`;

        if (query) {
            delete query.limit;

            if (Object.keys(query).length > 0) {
                // XXX fix me pagination

                const searchParams = new URLSearchParams();

                Object.entries(query).forEach(([key, values]) => {
                    if (Array.isArray(values)) {
                        values.forEach(value => {
                            searchParams.append(key, value);
                        });
                    } else {
                        searchParams.append(key, values);
                    }
                });

                url += url.indexOf('?') >= 0 ? '&' : '?';
                url += searchParams.toString();
            }
        }

        console.log('fetching', url);
        const result = await fetch(url, options);
        const body = await result.json();

        if (body.errors) {
            console.log(body.errors);
            throw body.errors[0];
        }

        return {
            status: result.status,
            body,
        };
    } catch (e) {
        throw {
            error: e,
        };
    }
}

const reshapeStrapiItem = <T>(item: StrapiItem<T>): ReshapedStrapiItem<T> => ({
    id: item?.id,
    ...item?.attributes,
});

const reshapeStrapiCollection = <I>(collection: StrapiCollection<I>) => {
    return collection.data?.map(reshapeStrapiItem) || [];
};

const reshapeStrapiImage = (name: string) => `/images/${name}` ?? 'default-image.svg';

const reshapeStrapiCustomer = (strapiCustomer: ReshapedStrapiItem<StrapiCustomer>): Customer => ({
    firstName: strapiCustomer.first_name,
    lastName: strapiCustomer.last_name,
});

const reshapeStrapiReview = (strapiReview: ReshapedStrapiItem<StrapiReview>): Review => ({
    languageCode: strapiReview.language_code,
    reviewText: strapiReview.review_text.replace(/^\s*Review\: "?/, '').replace(/"$/, ''),
    rating: strapiReview.rating,
    customer: reshapeStrapiCustomer(reshapeStrapiItem(strapiReview.customer.data)),
});

const reshapeStrapiReviewSummary = (
    strapiReviewSummary: ReshapedStrapiItem<StrapiReviewSummary>
): ReviewSummary => ({
    summary: strapiReviewSummary.summary.replace(/Would you like (.+)\?$/, ''),
});

const reshapeStrapiDescription = (
    StrapiDescription: ReshapedStrapiItem<StrapiDescription>
): Description => ({
    languageCode: StrapiDescription.language_code,
    description: StrapiDescription.description,
});

const reshapeStrapiProduct = (strapiProduct: ReshapedStrapiItem<StrapiProduct>): Product => {
    const url = reshapeStrapiImage(strapiProduct.image);
    const seo = { title: strapiProduct.name };
    return {
        ...seo,
        seo,
        handle: strapiProduct.id,
        featuredImage: { url },
        availableForSale: true,
        images: [{ url }],
        category: strapiProduct.category,
        priceRange: {
            maxVariantPrice: { amount: strapiProduct.price },
            minVariantPrice: { amount: strapiProduct.price },
        },
        descriptions: strapiProduct.productdescriptions?.data
            .map(reshapeStrapiItem)
            .map(reshapeStrapiDescription),
        reviews: strapiProduct.reviews?.data.map(reshapeStrapiItem).map(reshapeStrapiReview),
        reviewSummary: strapiProduct.reviewSummary,
        tags: [],
        options: [],
        variants: [],
    } as any as Product;
};

const reshapeStrapiProducts = (collection: StrapiCollection<StrapiProduct>): Product[] => {
    return reshapeStrapiCollection(collection).map(reshapeStrapiProduct);
};

const reshapeAmountsPrice = (price: number): Money => {
    return {
        amount: price.toString(),
        currencyCode: currencyCode,
    };
};

const reshapeOrder = (order: EcwidOrder): Cart => {
    const quantity = order?.cartItems?.reduce((n, { quantity }) => n + quantity, 0) || 0;

    let lines: CartItem[] = [];
    if (quantity > 0) {
        lines = order?.cartItems?.map(item => reshapeOrderLine(item)) || [];
    }

    return {
        id: order.id,
        checkoutUrl: `/checkout?id=${order.id}`,
        totalQuantity: quantity,
        cost: {
            subtotalAmount: reshapeAmountsPrice(order.amounts.subtotal),
            totalAmount: reshapeAmountsPrice(order.amounts.total),
            totalTaxAmount: reshapeAmountsPrice(order.amounts.tax),
        },
        lines: lines,
    };
};

const reshapeOrderLine = (orderLine: EcwidCartItem): CartItem => {
    const imgUrl = orderLine.productInfo?.mediaItem
        ? orderLine.productInfo?.mediaItem.image160pxUrl
        : '';

    let productId = orderLine.identifier.productId.toString();

    const selectedOptions = orderLine.identifier?.selectedOptions
        ? Object.entries(orderLine.identifier?.selectedOptions).map((opt: any) => ({
              name: opt[0],
              value: opt[1].choice,
          }))
        : [];

    if (selectedOptions.length > 0) {
        productId += '|' + selectedOptions.map(({ name, value }) => `${name}:${value}`).join('|');
    }

    const subTitle =
        selectedOptions.length > 0
            ? selectedOptions?.map(({ name, value }) => `${name}:${value}`).join(', ')
            : DEFAULT_OPTION;

    return {
        id: productId, // [Required]
        merchandise: {
            id: productId, // [Required]
            title: subTitle,
            selectedOptions: selectedOptions,
            product: {
                // handle: productId, // [Required]
                handle: `${orderLine.productInfo.slugs.forRouteWithId}-p${productId}`, // [Required]
                availableForSale: true,
                title: orderLine.productInfo.name, // [Required]
                descriptions: [],
                category: '',
                descriptionHtml: '',
                options: [],
                priceRange: {
                    maxVariantPrice: {
                        amount: orderLine.price.toString(),
                        currencyCode: currencyCode,
                    },
                    minVariantPrice: {
                        amount: orderLine.price.toString(),
                        currencyCode: currencyCode,
                    },
                },
                featuredImage: {
                    // [Required]
                    url: imgUrl,
                    altText: orderLine.productInfo.name,
                    width: 0,
                    height: 0,
                },
                seo: {
                    title: '',
                    description: '',
                },
                reviews: [],
                tags: [TAGS.cart],
                updatedAt: new Date().toISOString(),
                variants: [],
                images: [],
            },
        },
        quantity: orderLine.quantity, // [Required]
        cost: {
            // [Required]
            totalAmount: reshapeAmountsPrice(orderLine.price),
        },
    };
};

const reshapeCollection = (node: EcwidNode): Collection | undefined => {
    if (!node) {
        return undefined;
    }

    const metaTitle = node.seoTitle?.toString() || node.name;
    const metaDescription = node.seoDescription?.toString() || node.description;

    return {
        handle: node.id.toString(),
        title: node.name,
        description: node.description?.toString(),
        seo: {
            title: metaTitle,
            description: metaDescription,
        },
        path: `${node.url}`,
        updatedAt: '',
    };
};

const reshapeCollections = (nodes: EcwidNode[]): Collection[] => {
    return <Collection[]>(nodes || []).map(n => reshapeCollection(n)).filter(n => !!n);
};

export async function createCart(): Promise<Cart> {
    const res = await strapiFetch<EcwidCart>({
        method: 'POST',
        path: `/checkout/create`,
        tags: [TAGS.cart],
        payload: {
            lang: 'en',
        },
    });

    const cartId = res.body.checkoutId;

    cookies().set(`ec-${store_id}-session`, res.body.sessionToken);

    return {
        id: cartId,
        sessionToken: res.body.sessionToken,
        checkoutUrl: '',
        cost: {
            subtotalAmount: {
                amount: '',
                currencyCode: '',
            },
            totalAmount: {
                amount: '',
                currencyCode: '',
            },
            totalTaxAmount: {
                amount: '',
                currencyCode: '',
            },
        },
        lines: [],
        totalQuantity: 0,
    };
}

export async function addToCart(
    cartId: string,
    lines: { merchandiseId: string; quantity: number }[]
): Promise<Cart | undefined> {
    // We assume there is only one item to be added at a time
    // which looking at the code is the case. May need to keep
    // track to see if it ever gets implemented that multiple
    // items can be added at once.
    const line = lines[0];
    const idParts = line!.merchandiseId.split('|');

    const productId = idParts[0];
    const sessionToken = cookies().get(`ec-${store_id}-session`)?.value;

    const selectedOptions = {} as any;

    if (idParts.length > 1) {
        idParts.shift();

        idParts.map(part => {
            const option = part.split(':');
            selectedOptions[`${option[0]}`] = { type: 'DROPDOWN', choice: `${option[1]}` };
        });
    }

    const res = await strapiFetch<EcwidCheckout>({
        method: 'POST',
        path: `/checkout/add-cart-item`,
        tags: [TAGS.cart],
        payload: {
            lang: 'en',
            newCartItem: {
                identifier: {
                    productId: productId,
                    selectedOptions: selectedOptions,
                },
                quantity: 1,
                categoryId: 0,
                isPreorder: false,
            },
        },
        headers: {
            Authorization: 'Bearer ' + sessionToken,
        },
    });

    return reshapeOrder(res.body.checkout);
}

export async function removeFromCart(cartId: string, lineIds: string[]): Promise<Cart> {
    // We assume there is only one item to be removed at a time
    // which looking at the code is the case. May need to keep
    // track to see if it ever gets implemented that multiple
    // items can be removed at once.
    const line = lineIds[0];
    const idParts = line!.split('|');
    const productId = idParts[0];

    const sessionToken = cookies().get(`ec-${store_id}-session`)?.value;

    let selectedOptions = {} as any | undefined;

    if (idParts.length > 1) {
        idParts.shift();

        idParts.map(part => {
            const option = part.split(':');
            selectedOptions[`${option[0]}`] = { type: 'DROPDOWN', choice: `${option[1]}` };
        });
    } else {
        selectedOptions = undefined;
    }

    const res = await strapiFetch<EcwidCheckout>({
        method: 'POST',
        path: `/checkout/remove-cart-item`,
        tags: [TAGS.cart],
        payload: {
            lang: 'en',
            cartItemIdentifier: {
                productId: productId,
                selectedOptions: selectedOptions,
            },
        },
        headers: {
            Authorization: 'Bearer ' + sessionToken,
        },
    });

    return reshapeOrder(res.body.checkout);
}

export async function updateCart(
    cartId: string,
    lines: { id: string; merchandiseId: string; quantity: number }[]
): Promise<Cart> {
    const sessionToken = cookies().get(`ec-${store_id}-session`)?.value;

    const line = lines[0];
    const idParts = line!.merchandiseId.split('|');
    const productId = idParts[0];

    await removeFromCart(cartId, [line!.merchandiseId]);

    const selectedOptions = {} as any;

    if (idParts.length > 1) {
        idParts.shift();

        idParts.map(part => {
            const option = part.split(':');
            selectedOptions[`${option[0]}`] = { type: 'DROPDOWN', choice: `${option[1]}` };
        });
    }

    const res = await strapiFetch<EcwidCheckout>({
        method: 'POST',
        path: `/checkout/add-cart-item`,
        tags: [TAGS.cart],
        payload: {
            lang: 'en',
            newCartItem: {
                identifier: {
                    productId: productId,
                    selectedOptions: selectedOptions,
                },
                quantity: line?.quantity,
                categoryId: 0,
                isPreorder: false,
            },
        },
        headers: {
            Authorization: 'Bearer ' + sessionToken,
        },
    });

    return reshapeOrder(res.body.checkout);
}

export async function getCart(): Promise<Cart | undefined> {
    const sessionToken = cookies().get(`ec-${store_id}-session`)?.value;

    if (!sessionToken) {
        return undefined;
    }

    const res = await strapiFetch<EcwidCheckout>({
        method: 'POST',
        path: `/checkout`,
        tags: [TAGS.cart],
        payload: {
            lang: 'en',
        },
        headers: {
            Authorization: 'Bearer ' + sessionToken,
        },
    });

    if (!res.body) {
        return undefined;
    }

    return reshapeOrder(res.body.checkout);
}

export async function getMenu(handle: string): Promise<Menu[]> {
    if (handle == 'next-js-frontend-footer-menu') {
        return [];
    }

    const query = <Record<string, string | string[]>>{
        limit: '2',
    };

    const res = await strapiFetch<StrapiCollection<StrapiProductCategory>>({
        method: 'GET',
        path: `/productcategories`,
        tags: [TAGS.collections],
        query: query,
    });

    const menu =
        reshapeStrapiCollection(res.body).map(collection => ({
            path: `/?category=${collection.path}`,
            title: collection.name,
        })) || [];

    menu.sort((a, b) => a.title.localeCompare(b.title));

    return menu;
}

export async function getCategories(): Promise<Collection[]> {
    const baseUrl = '/search';

    const res = await strapiFetch<EcwidPagedResult<EcwidNode>>({
        method: 'GET',
        path: `/categories`,
        tags: [TAGS.collections],
        query: {
            cleanUrls: 'true',
            baseUrl: baseUrl,
        },
    });

    const collections = [
        {
            handle: '',
            title: 'All',
            description: 'All products',
            seo: {
                title: 'All',
                description: 'All products',
            },
            path: baseUrl,
            updatedAt: new Date().toISOString(),
        },
        ...reshapeCollections(res.body?.items),
    ];

    return <Collection[]>collections;
}

export async function getProducts({
    category,
}: {
    category?: string;
    reverse?: boolean;
    sortKey?: string;
} = {}): Promise<Product[]> {
    const query = <Record<string, string | string[]>>{};

    if (category) query['filters[category]'] = category;

    const res = await strapiFetch<StrapiCollection<StrapiProduct>>({
        method: 'GET',
        path: `/products`,
        query: query,
        tags: [TAGS.products],
    });

    if (res.body?.data) {
        return reshapeStrapiProducts(res.body);
    }

    console.log(`No collection found for \`${category}\``);
    return [];
}

export async function getProduct(handle: string): Promise<Product | undefined> {
    const productId = handle.replace(/^.*?\-p/g, '');

    const res = await strapiFetch<{ data: StrapiItem<StrapiProduct> }>({
        method: 'GET',
        path: `/products/${productId}`,
        tags: [TAGS.products],
        query: {
            'populate[0]': 'reviews',
            'populate[1]': 'reviews.customer',
            'populate[2]': 'productdescriptions',
        },
    });

    const ret = reshapeStrapiProduct(reshapeStrapiItem(res.body?.data));
    return ret;
    // return new Promise(resolve => setTimeout(() => resolve(ret), 2000));
}

export async function getReviewSummary(
    handle: string,
    lang: string
): Promise<ReviewSummary | undefined> {
    const res = await strapiFetch<{ data: StrapiItem<StrapiReviewSummary> }>({
        method: 'POST',
        path: '/review/summary',
        tags: [TAGS.products],
        query: { id: handle, lang },
    });

    return reshapeStrapiReviewSummary(reshapeStrapiItem(res.body?.data));
}

// This is called from `app/api/revalidate.ts` so providers can control revalidation logic.
export async function revalidate(req: NextRequest): Promise<NextResponse> {
    // We always need to respond with a 200 status code to Ecwid,
    // otherwise it will continue to retry the request.
    const collectionWebhooks = ['category.created', 'category.deleted', 'category.updated'];
    const productWebhooks = ['product.created', 'product.deleted', 'product.updated'];
    const profileWebhooks = ['profile.updated'];
    const { eventType } = await req.json();
    const secret = headers().get('X-Ecwid-Revalidation-Secret') || 'unknown';

    const isCollectionUpdate = collectionWebhooks.includes(eventType);
    const isProductUpdate = productWebhooks.includes(eventType);
    const isProfileUpdate = profileWebhooks.includes(eventType);

    if (!secret || secret !== process.env.ECWID_REVALIDATION_SECRET) {
        console.error('Invalid revalidation secret.');
        return NextResponse.json({ status: 200 });
    }

    if (!isCollectionUpdate && !isProductUpdate && !isProfileUpdate) {
        // We don't need to revalidate anything for any other topics.
        return NextResponse.json({ status: 200 });
    }

    if (isProductUpdate) {
        revalidateTag(TAGS.products);
    }

    if (isCollectionUpdate) {
        revalidateTag(TAGS.collections);
    }

    if (isProfileUpdate) {
        revalidateTag(TAGS.profile);
    }

    return NextResponse.json({ status: 200, revalidated: true, now: Date.now() });
}
