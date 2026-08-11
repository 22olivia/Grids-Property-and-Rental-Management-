'use client';

import { useTranslations } from 'next-intl';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import {
  Button, Field, Input, Textarea,
  SelectRoot, SelectTrigger, SelectValue, SelectContent, SelectItem,
} from '@/design-system/ui';
import { activityFormSchema, type ActivityFormValues } from '../schemas/crm-schemas';
import { ACTIVITY_TYPES } from '../types';
import { activityLabelKey } from '../constants';

/** FR-CRM-004 — record calls, notes, meetings, tasks, reminders, messages. */
export function ActivityComposer({
  onSubmit,
  isSubmitting,
}: {
  onSubmit: (values: ActivityFormValues) => Promise<void>;
  isSubmitting: boolean;
}) {
  const t = useTranslations('crm');
  const { register, handleSubmit, watch, setValue, reset, formState: { errors } } =
    useForm<ActivityFormValues>({
      resolver: zodResolver(activityFormSchema),
      defaultValues: { type: 'note', summary: '', detail: null, dueAt: null },
    });

  const type = watch('type');
  // Only tasks and reminders carry a due date — FR-CRM-004 distinguishes them.
  const needsDueDate = type === 'task' || type === 'reminder';

  return (
    <form
      noValidate
      className="flex flex-col gap-4"
      onSubmit={handleSubmit(async (values) => {
        await onSubmit(values);
        reset();
      })}
    >
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label={t('field.activityType')} required>
          <SelectRoot
            value={type}
            onValueChange={(value) => setValue('type', value as ActivityFormValues['type'])}
          >
            <SelectTrigger><SelectValue /></SelectTrigger>
            <SelectContent>
              {ACTIVITY_TYPES.map((value) => (
                <SelectItem key={value} value={value}>{t(activityLabelKey(value))}</SelectItem>
              ))}
            </SelectContent>
          </SelectRoot>
        </Field>
        <Field
          label={t('field.summary')}
          required
          error={errors.summary ? t('validation.required') : undefined}
        >
          <Input {...register('summary')} autoComplete="off" />
        </Field>
      </div>

      <Field label={t('field.detail')}>
        <Textarea {...register('detail')} rows={3} />
      </Field>

      {needsDueDate && (
        <Field label={t('field.dueAt')} description={t('field.dueAtHelp')}>
          <Input {...register('dueAt')} type="datetime-local" contentDirection="ltr" />
        </Field>
      )}

      <div className="flex justify-end">
        <Button type="submit" size="sm" loading={isSubmitting} loadingLabel={t('activities.add')}>
          {t('activities.add')}
        </Button>
      </div>
    </form>
  );
}
