export type Maybe<T> = T | null;

export type Cart = {
    id: string;
    sessionToken?: string;
    checkoutUrl: string;
    cost: {
        subtotalAmount: Money;
        totalAmount: Money;
        totalTaxAmount: Money;
    };
    totalQuantity: number;
    lines: CartItem[];
};

export type CartItem = {
    id: string;
    quantity: number;
    cost: {
        totalAmount: Money;
    };
    merchandise: {
        id: string;
        title: string;
        selectedOptions: {
            name: string;
            value: string;
        }[];
        product: Product;
    };
};

export type Collection = {
    handle: string;
    title: string;
    path: string;
    description: string;
    seo: SEO;
    updatedAt: string;
};

export type Image = {
    url: string;
    width: number;
    height: number;
    altText?: string;
};

export type Menu = {
    title: string;
    path: string;
};

export type Money = {
    amount: string;
    currencyCode: string;
};

export type Customer = {
    firstName: string;
    lastName: string;
};

export type Review = {
    languageCode: string;
    reviewText: string;
    rating: number;
    customer: Customer;
};

export type ReviewSummary = {
    summary: string;
};

export type Description = {
    languageCode: string;
    description: string;
};

export type Product = {
    tags: any;
    featuredImage: Image;
    handle: string;
    availableForSale: boolean;
    title: string;
    category: string;
    descriptions: Description[];
    descriptionHtml: string;
    options: ProductOption[];
    priceRange: {
        maxVariantPrice: Money;
        minVariantPrice: Money;
    };
    seo: SEO;
    // tags: string[];
    updatedAt: string;
    variants: ProductVariant[];
    images: Image[];
    reviews: Review[];
};

export type ProductOption = {
    id: string;
    name: string;
    values: string[];
};

export type ProductVariant = {
    id: string;
    title: string;
    availableForSale: boolean;
    selectedOptions: {
        name: string;
        value: string;
    }[];
    // price: Money;
    price: number;
};

export type SEO = {
    title: string;
    description: string;
};

export type StrapiCustomer = {
    first_name: string;
    last_name: string;
};

export type StrapiReview = {
    language_code: string;
    review_text: string;
    rating: number;
    customer: { data: StrapiItem<StrapiCustomer> };
};

export type StrapiReviewSummary = {
    summary: string;
};

export type StrapiDescription = {
    language_code: string;
    description: string;
};

export type StrapiProduct = {
    name: string;
    price: number;
    category: string;
    image: string;
    productdescriptions: { data: StrapiItem<StrapiDescription>[] };
    reviews: { data: StrapiItem<StrapiReview>[] };
    reviewSummary: string;
};

export type StrapiProductCategory = {
    name: string;
    path: string;
};

export type ReshapedStrapiItem<I> = {
    id: string;
    updatedAt: string;
    createdAt: string;
} & I;

export type StrapiItem<I> = {
    id: string;
    attributes: I & {
        updatedAt: string;
        createdAt: string;
    };
};

export type StrapiCollection<I> = {
    data: StrapiItem<I>[];
};

export type EcwidCurrencyNode = {
    formatsAndUnits: {
        currency: string;
    };
};

export type EcwidLatestStatsNode = {
    productsUpdated: string;
    profileUpdated: string;
    categoriesUpdated: string;
};

export type EcwidElement = {
    id: string;
    contentType: string;
    properties: { [id: string]: any };
};

export type EcwidNode = EcwidElement & {
    enabled: boolean;
    name: string;
    url: string;
    createDate: string;
    updateDate: string;
    description: string;
    inStock: boolean;
    price: number;
    defaultDisplayedPrice: number;
    defaultDisplayedPriceFormatted: string;
    compareToPrice: number;
    seoTitle: string;
    seoDescription: string;
    originalImage: EcwidMedia;
    galleryImages: EcwidMedia[];
    relatedProducts: EcwidRelatedProducts;
    combinations: EcwidVariation[];
    options: EcwidProductOption[];
};

export type EcwidRelatedProducts = {
    productIds: number[];
    relatedCategory: EcwidRelatedCategory;
};

export type EcwidRelatedCategory = {
    enabled: boolean;
    categoryId: number;
    productCount: number;
};

export type EcwidMedia = {
    id: string;
    name: string;
    mediaType: string;
    url: string;
    extension: string;
    width: number;
    height: number;
    bytes: null;
    properties: { [id: string]: any };
};

export type EcwidVariation = {
    id: number;
    inStock: boolean;
    combinationNumber: number;
    sku: string;
    thumbnailUrl: string;
    imageUrl: string;
    smallThumbnailUrl: string;
    hdThumbnailUrl: string;
    originalImageUrl: string;
    quantity: number;
    unlimited: boolean;
    price: number;
    compareToPrice: number;
    weight: number;
    options: EcwidVariationOptionValue[];
};

export type EcwidVariationOptionValue = {
    name: string;
    value: string;
};

export type EcwidProductOption = {
    type: string;
    name: string;
    choices: EcwidProductOptionChoice[];
    defaultChoice: number;
    required: boolean;
};

export type EcwidProductOptionChoice = {
    text: string;
    priceModifier: number;
    priceModifierType: string;
};

export type EcwidCart = {
    checkoutId: string;
    sessionToken: string;
};

export type EcwidCheckout = {
    checkout: EcwidOrder;
    notices: Array<any>;
};

export type EcwidOrder = {
    id: string;
    identifiers: {
        abandonedCartId: string;
        internalOrderId: number;
    };
    payment: {};
    shipping: {
        method: string;
    };
    cartItems: EcwidCartItem[];
    discounts: {};
    amounts: EcwidAmounts;
};

export type EcwidAmounts = {
    subtotal: number;
    subtotalWithoutTax: number;
    total: number;
    totalWithoutTax: number;
    tax: number;
    couponDiscount: number;
    volumeDiscount: number;
    customerGroupDiscount: number;
    customerGroupVolumeDiscount: number;
    discount: number;
    shipping: number;
    shippingWithoutTax: number;
    handlingFee: number;
    handlingFeeWithoutTax: number;
    isPricesIncludeTax: boolean;
};

export type EcwidCartItem = {
    identifier: {
        productId: number;
        selectedOptions: {};
    };
    quantity: number;
    categoryId: number;
    price: number;
    productInfo: {
        description: string;
        isBaseProductQuantity: boolean;
        name: string;
        productPrice: number;
        sku: string;
        slugs: {
            forRouteWithId: string;
        };
        weight: {
            value: number;
            formattedValue: string;
        };
        mediaItem: {
            image160pxUrl: string;
        };
    };
};

export type EcwidCurrency = {
    id: string;
    code: string;
};

export type EcwidAdjustedPrice = {
    value: EcwidPrice;
};

export type EcwidPrice = {
    currency: EcwidCurrency;
    withoutTax: number;
    tax: number;
    withTax: number;
};

export type EcwidPagedResult<T> = {
    total: number;
    count: number;
    offset: number;
    limit: number;
    items: T[];
};
