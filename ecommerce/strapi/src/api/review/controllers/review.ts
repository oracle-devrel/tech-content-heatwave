/**
 * review controller
 */

import { factories } from '@strapi/strapi'

export default factories.createCoreController('api::review.review', {
    async reviewSummary(ctx) {
        if (ctx.request.query.id === undefined) {
            return ctx.badRequest('id parameter required')
        }

        const result = strapi.db.connection.raw('call summarize_review(?, ?)', [ctx.request.query.id, ctx.request.query.lang]);

        // Append the custom result
        const summary = (await result)[0][0][0]?.summary;
        return {
            data: {
                attributes: { summary }
            }
        };
    }
});
