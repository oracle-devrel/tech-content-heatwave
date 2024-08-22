import { XMarkIcon } from '@heroicons/react/24/outline';
import { Pill } from 'components/pill';

export default function IntroContents({ close }: { close: () => void }) {
    return (
        <div className="text-slate-700 rounded-lg border bg-white border-neutral-200 h-full">
            <section className="text-lg mx-auto px-4 pb-2 md:grid-cols-6 md:grid-rows-1 ">
                <div className="flex items-center justify-between">
                    <div className="font-semibold">HeatWave GenAI E-Commerce Demo</div>
                    <button
                        aria-label="Close cart"
                        onClick={close}
                    >
                        <div className="relative flex h-11 w-11 items-center justify-center text-black transition-colors dark:border-neutral-700 dark:text-white">
                            <XMarkIcon className="h-6 transition-all ease-in-out hover:scale-110" />
                        </div>
                    </button>
                </div>
            </section>

            <section className="text-md mx-auto px-4 pb-4">
                <div className="font-medium">Demo showcase</div>
                <ul className="ml-4 mt-1 list-disc text text-gray-600">
                    <li>
                        <div className="flex items-center">
                            <span>Review summary</span>
                            <Pill>HeatWave GenAI</Pill>
                        </div>
                    </li>
                    <li>
                        <div className="flex items-center">
                            <span>Locale enabled</span>
                            <Pill>HeatWave GenAI</Pill>
                        </div>
                    </li>
                </ul>
            </section>

            <section className="text-md mx-auto px-4 pb-4">
                <div className="font-medium">Sample data</div>
                <ul className="ml-4 mt-1 list-disc text text-gray-600">
                    <li>10 products</li>
                    <li>20 customers</li>
                    <li>
                        <div className="flex items-center">
                            <span>75 product reviews</span>
                            <Pill>HeatWave GenAI</Pill>
                        </div>
                    </li>
                    <li>
                        <div className="flex items-center">
                            <span>50 product descriptions</span>
                            <Pill>HeatWave GenAI</Pill>
                        </div>
                    </li>
                    <li>
                        <div className="flex items-center">
                            <span>5 languages (EN, FR, IT, ES, DE)</span>
                            <Pill>HeatWave GenAI</Pill>
                        </div>
                    </li>
                </ul>
            </section>

            <h1 className="text-md mx-auto mb-2"></h1>
            <section className="text-md mx-auto px-4 pb-4">
                <div className="font-medium">Technology stack</div>
                <ul className="ml-4 mt-1 list-disc text text-gray-600">
                    <li>HeatWave GenAI</li>
                    <li>
                        <span>Middleware REST server </span>
                        <Pill color="gray">
                            <a
                                className="text-sm text-rose-700"
                                href="http://strapi.io"
                                target="_blank"
                            >
                                strapi
                            </a>
                        </Pill>
                    </li>
                    <li>
                        <span>Web front-end </span>
                        <Pill color="gray">
                            <a
                                className="text-sm text-rose-700"
                                href="http://nextjs.org"
                                target="_blank"
                            >
                                next.js
                            </a>
                        </Pill>
                    </li>
                </ul>
            </section>
        </div>
    );
}
