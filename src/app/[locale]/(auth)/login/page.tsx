'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button, Card, CardHeader, CardTitle, Field, Input } from '@/design-system/ui';
import { FormErrorSummary } from '@/domain/components/form-error-summary';
import { useRouter } from '@/lib/i18n/routing';
import { ApiError } from '@/lib/api/types';
import { DEMO_MODE } from '@/lib/data/repository';
import { Alert } from '@/design-system/ui';

/**
 * Login — LIVE against POST /api/v1/login via the BFF.
 *
 * The BFF exchanges credentials for a Sanctum token and stores it in an
 * httpOnly cookie. No token is returned to this component.
 *
 * The backend restricts sign-in to super_admin, owner, manager and tenant
 * (AuthController line 108) and returns that restriction as a validation error
 * on `email`, so it lands on the field and needs no special casing here.
 */
const loginSchema = z.object({
  email: z.string().min(1, 'required').email('email'),
  password: z.string().min(1, 'required'),
});
type LoginValues = z.infer<typeof loginSchema>;

export default function LoginPage() {
  const t = useTranslations('auth');
  const router = useRouter();
  const [formErrors, setFormErrors] = useState<string[]>([]);

  const { register, handleSubmit, setError, formState: { errors, isSubmitting } } =
    useForm<LoginValues>({ resolver: zodResolver(loginSchema) });

  async function onSubmit(values: LoginValues) {
    setFormErrors([]);
    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'same-origin',
        body: JSON.stringify(values),
      });

      const payload = await response.json();

      if (!response.ok) {
        // Laravel's { message, errors: { field: [msg] } }, already normalised
        // by the BFF into ApiErrorItem[].
        const error = new ApiError(response.status, payload.errors ?? [], null);
        const fieldErrors = error.fieldErrors;
        let bound = false;
        for (const [field, message] of Object.entries(fieldErrors)) {
          if (field === 'email' || field === 'password') {
            setError(field, { type: 'server', message });
            bound = true;
          }
        }
        if (!bound) setFormErrors([payload.message ?? t('errors.unexpected')]);
        return;
      }

      router.push('/console/assets/properties');
      router.refresh();
    } catch {
      setFormErrors([t('errors.unexpected')]);
    }
  }

  const message = (key: string | undefined) =>
    key === 'required' || key === 'email' ? t(`validation.${key}`) : key;

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-xl">{t('login.title')}</CardTitle>
      </CardHeader>

      {/* Shown only in demo mode so a reviewer can sign in without the
          Laravel backend running. Never rendered against the real API. */}
      {DEMO_MODE && (
        <Alert tone="info" title={t('login.demoTitle')} className="mb-4">
          {t('login.demoBody')}
        </Alert>
      )}

      <FormErrorSummary messages={formErrors} />

      {/* noValidate: browser bubbles are not localisable and are announced
          inconsistently. Our own messages are both. */}
      <form onSubmit={handleSubmit(onSubmit)} noValidate className="flex flex-col gap-4">
        <Field label={t('login.identifier')} required error={message(errors.email?.message)}>
          <Input {...register('email')} type="email" autoComplete="username" contentDirection="ltr" />
        </Field>

        <Field label={t('login.password')} required error={message(errors.password?.message)}>
          <Input {...register('password')} type="password" autoComplete="current-password" />
        </Field>

        <Button type="submit" loading={isSubmitting} loadingLabel={t('login.submitting')}>
          {t('login.submit')}
        </Button>

        {/* No "forgotten password" link yet. The backend HAS /forgot-password
            and /reset-password, but the reset flow is still unspecified on the
            product side (MI-07) — token lifetime, delivery channel and
            re-authentication rules. The endpoints exist; the journey does not. */}
      </form>
    </Card>
  );
}
