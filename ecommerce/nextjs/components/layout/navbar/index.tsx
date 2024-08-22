'use client';

import Cart from 'components/cart';
import OpenCart from 'components/cart/open-cart';
import LogoSquare from 'components/logo-square';
import { Menu } from 'lib/ecwid/types';
import Link from 'next/link';
import { Suspense, useContext } from 'react';
import MobileMenu from './mobile-menu';
import Search from './search';
import MenuItem from './menu-item';
import { LanguageMenu } from './language-menu';
import { CategoryContext, LocaleContext } from 'components/context';
const { SITE_NAME } = process.env;

export default function Navbar({ menu }: { menu: Menu[] }) {
    const locale = useContext(LocaleContext);
    const { category } = useContext(CategoryContext);

    return (
        <nav className="relative flex items-center justify-between p-4 lg:px-6">
            <div className="block flex-none md:hidden">
                <MobileMenu menu={menu} />
            </div>
            <div className="flex w-full items-center">
                <div className="flex w-full md:w-1/3">
                    <Link
                        href={`/${locale}`}
                        className="mr-2 flex w-full items-center justify-center md:w-auto lg:mr-6"
                    >
                        <LogoSquare />
                        <div className="ml-2 flex-none text-sm font-medium uppercase md:hidden lg:block">
                            {SITE_NAME}
                        </div>
                    </Link>
                    {menu.length ? (
                        <ul className="hidden gap-6 text-sm md:flex md:items-center">
                            {menu.map((item: Menu) => (
                                <li key={item.title}>
                                    <MenuItem
                                        path={`/${locale}${item.path}`}
                                        query={{ category: item.title.toLowerCase() }}
                                        selected={
                                            category?.toLowerCase() === item.title.toLowerCase()
                                        }
                                    >
                                        {item.title}
                                    </MenuItem>
                                </li>
                            ))}
                        </ul>
                    ) : null}
                </div>
                <div className="hidden justify-center md:flex md:w-1/3">
                    <Search />
                </div>
                <div className="flex md:w-1/3 items-center justify-center">
                    <ul className="hidden gap-6 text-sm md:flex md:items-center">
                        <LanguageMenu />
                    </ul>
                </div>
                <div className="flex justify-end">
                    <Suspense fallback={<OpenCart />}>
                        <Cart />
                    </Suspense>
                </div>
            </div>
        </nav>
    );
}
