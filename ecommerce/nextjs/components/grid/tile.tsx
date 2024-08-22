import clsx from 'clsx';
import Image from 'next/image';
import Label from '../label';
import LoadingImage from 'components/images/loading-image';

export function GridTileImage({
    active,
    label,
    ...props
}: {
    isInteractive?: boolean;
    active?: boolean;
    label?: {
        title: string;
        amount: string;
        currencyCode: string;
        position?: 'bottom' | 'center';
    };
} & React.ComponentProps<typeof Image>) {
    return (
        <div
            className={clsx(
                'group flex h-full w-full items-center justify-center overflow-hidden rounded-lg border bg-white hover:border-blue-600 dark:bg-black',
                {
                    relative: label,
                    'border-2 border-blue-600': active,
                    'border-neutral-200 dark:border-neutral-800': !active,
                }
            )}
        >
            {props.src ? <LoadingImage {...props} /> : undefined}
            {label ? (
                <Label
                    title={label.title}
                    amount={label.amount}
                    currencyCode={label.currencyCode}
                    position={label.position}
                />
            ) : null}
        </div>
    );
}
