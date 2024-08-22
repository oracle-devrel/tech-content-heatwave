import { Dispatch, SetStateAction, createContext } from 'react';

export const CategoryContext = createContext({
    category: undefined as string | undefined,
    setCategory: undefined as any as Dispatch<SetStateAction<string | undefined>>,
});
export const LocaleContext = createContext('en');
