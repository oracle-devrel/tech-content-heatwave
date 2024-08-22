module.exports = {
    extends: ['next', 'prettier'],
    plugins: ['unicorn', 'prettier'],
    rules: {
        'no-unused-vars': [
            'error',
            {
                args: 'after-used',
                caughtErrors: 'none',
                ignoreRestSiblings: true,
                vars: 'all',
                varsIgnorePattern: '^_',
                argsIgnorePattern: '^_',
            },
        ],
        'prettier/prettier': ['error'],
        'prefer-const': 'error',
        'react-hooks/exhaustive-deps': 'error',
        'unicorn/filename-case': [
            'error',
            {
                case: 'kebabCase',
            },
        ],
    },
    parserOptions: {
        babelOptions: {
            presets: [require.resolve('next/babel')],
        },
    },
};
