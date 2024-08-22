import MenuItem from './menu-item';
import { flags } from './flags';
import { languages } from 'components/locale';
import { usePathname } from 'next/navigation';
import { LocaleContext } from 'components/context';
import { useContext } from 'react';
import clsx from 'clsx';

export function LanguageMenu() {
    const locale = useContext(LocaleContext);
    const pathname = usePathname();
    const [_0, _currentLanguage, ...rest] = pathname.split('/');

    return (
        <>
            {languages.map(language => (
                <li
                    key={language}
                    className={clsx(
                        locale === language && 'border-0 border-b border-slate-400',
                        'pb-2'
                    )}
                >
                    <MenuItem path={`/${language}/${rest.join('/')}`}>
                        <span className="w-px[96] h-px[96]">{flags[language]}</span>
                    </MenuItem>
                </li>
            ))}
        </>
    );
}
