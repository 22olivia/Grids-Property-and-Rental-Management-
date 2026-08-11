'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { Trash2 } from 'lucide-react';
import { Button, ConfirmDialog, toast } from '@/design-system/ui';
import { toDisplayError } from '@/lib/api/display-error';

/**
 * Destructive delete with confirmation.
 *
 * Shared because every resource detail screen needs the same behaviour, and
 * the details are easy to get subtly wrong per screen:
 *
 *  - the confirm button names the ACTION, never "OK", so someone reading only
 *    the buttons still knows what happens;
 *  - a failed delete surfaces the server's own reason. The API can refuse for
 *    reasons the UI cannot know — a foreign-key constraint, a policy — and
 *    replacing that with a generic message hides the only useful information;
 *  - navigation happens only after the delete resolves. Redirecting first
 *    would show a success that may not have occurred.
 */
export function DeleteAction({
  label,
  title,
  description,
  confirmLabel,
  onDelete,
  onDeleted,
}: {
  label: string;
  title: string;
  description: string;
  confirmLabel: string;
  onDelete: () => Promise<void>;
  onDeleted: () => void;
}) {
  const tc = useTranslations('common');
  const [open, setOpen] = useState(false);

  return (
    <>
      <Button variant="secondary" onClick={() => setOpen(true)}>
        <Trash2 className="size-4 text-[var(--color-danger)]" aria-hidden="true" />
        {label}
      </Button>

      <ConfirmDialog
        open={open}
        onOpenChange={setOpen}
        title={title}
        description={description}
        confirmLabel={confirmLabel}
        cancelLabel={tc('cancel')}
        closeLabel={tc('close')}
        destructive
        onConfirm={async () => {
          try {
            await onDelete();
            onDeleted();
          } catch (error) {
            const display = toDisplayError(error, tc('unexpectedError'));
            toast.error(display?.message ?? tc('unexpectedError'));
            // Rethrow so the dialog stays open on failure — closing it would
            // imply the delete succeeded.
            throw error;
          }
        }}
      />
    </>
  );
}
