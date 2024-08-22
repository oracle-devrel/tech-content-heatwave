/* Copyright (c) 2024, Oracle and/or its affiliates. */
import { execSync } from 'child_process';

// See full list at:
// https://confluence.oraclecorp.com/confluence/display/CORPARCH/Internal+Use+Third-Party+Blanket+Approval
const ALLOWED = [
    '0BSD',
    'Apache 2.0',
    'Apache-2.0',
    'BlueOak-1.0.0',
    'BSD',
    'BSD*',
    'BSD-2-Clause',
    'BSD-3-Clause',
    'CC0-1.0',
    'CC-BY-3.0',
    'CC-BY-4.0',
    'ISC',
    'MIT',
    'MIT*',
    'MPL-2.0',
    'Python-2.0',
    'Unlicense',
    'UPL-1.0',
    'UNLICENSED',
    'WTFPL',
];
const OR = ' OR ';
const AND = ' AND ';

const getLicenses = () => {
    const command = 'npx npx license-checker-rseidelsohn --development';
    return String(execSync(command)).trim();
};
const validateLicense = (license: string) => ALLOWED.includes(license);
const validateLicenseString = (licenseString: string) => {
    if (licenseString.indexOf(OR) > 0) {
        const toCheck = licenseString.split(OR);
        return toCheck.find(validateLicense);
    } else if (licenseString.indexOf(AND) > 0) {
        const toCheck = licenseString.split(AND);
        return toCheck
            .map(validateLicense)
            .reduce((previous, current) => previous && current, true);
    } else {
        const toCheck = licenseString;
        return validateLicense(toCheck);
    }
};
const validateLicenses = (licenses: string) => {
    const disallowed = [];

    for (const line of licenses.split('\n')) {
        const match = line.match(/licenses: (.+)/);
        const matched = match?.[1];
        if (!matched) continue;
        const licenses = matched.replaceAll(/\(|\)/g, '');
        const allowed = validateLicenseString(licenses);
        if (!allowed) disallowed.push(licenses);
    }

    return disallowed;
};

const licenses = getLicenses();
const disallowed = validateLicenses(licenses);

if (disallowed.length > 0) {
    console.log('Disallowed development licenses found', disallowed);
    process.exit(1);
}

console.log('Development licenses ok!');
