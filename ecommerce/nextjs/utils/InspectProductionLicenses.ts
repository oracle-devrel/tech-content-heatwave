/* Copyright (c) 2024, Oracle and/or its affiliates. */
import { execSync } from 'child_process';
import fs from 'fs';

const snapshotFilename = './production-licenses.txt';
const command = 'npx license-checker-rseidelsohn --production';
const cwd = process.cwd();

const getLicenses = () => {
    return String(execSync(command)).replaceAll(cwd, '.');
};
const printSnapshotLicenses = (licenses: string) => {
    console.log('========== SNAPSHOT PRODUCTION LICENSES ==============');
    console.log();
    console.log(licenses);
    console.log();
};
const printProductionLicenses = (licenses: string) => {
    console.log('========== CURRENT PRODUCTION LICENSES ==============');
    console.log();
    console.log(licenses);
};
const update = () => {
    fs.writeFileSync(snapshotFilename, licenses);
    console.log('Production license snapshot file updated:', snapshotFilename);
    process.exit(0);
};
const fail = () => {
    printSnapshotLicenses(snapshot);
    printProductionLicenses(licenses);
    console.log('Production licenses do not match snapshot! Run this tool with `-u` to update.');
    process.exit(1);
};
const success = () => {
    printProductionLicenses(licenses);
    console.log('Production licenses ok!');
};

const licenses = getLicenses();
const snapshot = String(fs.readFileSync(snapshotFilename));

if (process.argv[2] === '-u') update();
if (licenses !== snapshot) fail();

success();
