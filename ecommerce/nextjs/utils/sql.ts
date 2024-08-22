// curl http://localhost:1337/api/reviews?pagination%5BpageSize%5D=100 > reviews.json
// curl http://localhost:1337/api/products > products.json

import products from './products.json';
import reviews from './reviews.json';

console.log(
    reviews.data
        .map(review => {
            const product_id = products.data.find(
                product =>
                    review.attributes.review_text
                        .toLowerCase()
                        .indexOf(product.attributes.name.toLowerCase()) >= 0
            )?.id;
            return `update reviews set product_id = ${product_id} where id = ${review.id};`;
        })
        .join('\n')
);
