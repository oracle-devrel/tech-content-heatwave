import { Locale } from 'components/locale';
import { getReviewSummary } from 'lib/ecwid';

function RenderReviewSummary({ reviewSummary }: { reviewSummary?: string }) {
    return reviewSummary ? (
        <>
            <div className="text-sm">{reviewSummary}</div>
        </>
    ) : undefined;
}

export async function ProductReviewSummary({ locale, id }: { id?: string } & Locale) {
    if (!id) return;

    const reviewSummary = await getReviewSummary(id, locale);

    return <RenderReviewSummary reviewSummary={reviewSummary?.summary} />;
}
