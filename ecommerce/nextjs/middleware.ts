import { NextRequest, NextResponse } from 'next/server';

const locales = ['en', 'fr', 'it', 'de', 'es', 'image', 'images', '_next', 'api', 'static'];

function redirect(request: NextRequest, pathname: string) {
    request.nextUrl.pathname = `/${pathname}`;
    return NextResponse.redirect(request.nextUrl);
}

export function middleware(request: NextRequest) {
    const { pathname } = request.nextUrl;

    // Check if there is any supported locale in the pathname
    const pathnameHasLocale = locales.some(
        locale => pathname.startsWith(`/${locale}/`) || pathname === `/${locale}`
    );
    if (pathnameHasLocale) return;

    // Redirect if there is no locale
    return redirect(request, 'en');
}
