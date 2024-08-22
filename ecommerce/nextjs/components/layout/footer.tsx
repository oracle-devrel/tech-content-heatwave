import Link from 'next/link';

import FooterMenu from 'components/layout/footer-menu';
import LogoSquare from 'components/logo-square';
import { getMenu } from 'lib/ecwid';

const { COMPANY_NAME, SITE_NAME } = process.env;

export default async function Footer() {
    const currentYear = new Date().getFullYear();
    const copyrightDate = 2023 + (currentYear > 2023 ? `-${currentYear}` : '');
    const menu = await getMenu('next-js-frontend-footer-menu');
    const copyrightName = COMPANY_NAME || SITE_NAME || '';

    return (
        <footer className="text-sm text-neutral-500 dark:text-neutral-400">
            <div className="mx-auto flex w-full max-w-7xl flex-col gap-6 border-t border-neutral-200 px-6 py-12 text-sm dark:border-neutral-700 md:flex-row md:gap-12 md:px-4 min-[1320px]:px-0">
                <div>
                    <Link
                        className="flex items-center gap-2 text-black dark:text-white md:pt-1"
                        href="/"
                    >
                        <LogoSquare size="sm" />
                        <span className="uppercase">{SITE_NAME}</span>
                    </Link>
                </div>
                <FooterMenu menu={menu} />
                <div className="md:ml-auto">
                    <a
                        className="flex h-8 w-max flex-none items-center justify-center rounded-md border border-neutral-200 bg-white text-xs text-black dark:border-neutral-700 dark:bg-black dark:text-white"
                        aria-label="Deploy on Vercel"
                        href="https://vercel.com/new/clone?repository-url=https%3A%2F%2Fgithub.com%2FEcwid%2Fecwid-nextjs-commerce&repository-name=ecwid-nextjs-commerce&env=ECWID_STORE_ID,ECWID_API_KEY,COMPANY_NAME,SITE_NAME"
                    >
                        <span className="px-3">▲</span>
                        <hr className="h-full border-r border-neutral-200 dark:border-neutral-700" />
                        <span className="px-3">Deploy</span>
                    </a>
                </div>
            </div>
            <div className="border-t border-neutral-200 py-6 text-sm dark:border-neutral-700">
                <div className="mx-auto flex w-full max-w-7xl flex-col items-center gap-1 px-4 md:flex-row md:gap-0 md:px-4 min-[1320px]:px-0">
                    <p>
                        &copy; {copyrightDate} {copyrightName}
                        {copyrightName.length && !copyrightName.endsWith('.') ? '.' : ''} All rights
                        reserved.
                    </p>
                    <hr className="mx-4 hidden h-4 w-[1px] border-l border-neutral-400 md:inline-block" />
                    <p>Designed in California</p>
                    <p className="md:ml-auto">
                        <a
                            href="https://ecwid.com"
                            className="text-black dark:text-white"
                        >
                            Crafted by Ecwid by Lightspeed
                        </a>
                    </p>
                </div>
            </div>
        </footer>
    );
}
