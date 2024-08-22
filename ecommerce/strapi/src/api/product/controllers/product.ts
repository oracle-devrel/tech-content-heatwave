/**
 * product controller
 */

import { factories } from '@strapi/strapi'

export default factories.createCoreController('api::product.product', ({ strapi }) => ({
    async findOne(ctx) {
        // Initiate the db call for the review
        // const summary = strapi.db.connection.raw('call summarize_review(?)', ctx.params.id);

        // Call the default parent controller action
        const result = await super.findOne(ctx);

        // Append the custom result
        // result.data.attributes.reviewSummary = (await summary)[0][0][0]?.summary;

        // Return the aggregate
        return result;
    },
}));
