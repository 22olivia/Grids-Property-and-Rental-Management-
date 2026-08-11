import { getRequestConfig } from 'next-intl/server';
import { routing } from './routing';
import { isLocale } from './config';

export default getRequestConfig(async ({ requestLocale }) => {
  const requested = await requestLocale;

  // `hasLocale` is a next-intl v4 export and does not exist in v3.x, which is
  // the major version this project targets. `isLocale` is our own type guard
  // over the same locale list, so the behaviour is identical without pulling
  // in a major upgrade.
  const locale = requested && isLocale(requested) ? requested : routing.defaultLocale;

  return {
    locale,
    messages: (await import(`../../../messages/${locale}.json`)).default,
    // All timestamps cross the API boundary in UTC (NFR-DATA-001). The display
    // timezone is resolved per request from company/user settings once that
    // contract exists — see MI-08.
    timeZone: 'UTC',
    now: new Date(),
  };
});
