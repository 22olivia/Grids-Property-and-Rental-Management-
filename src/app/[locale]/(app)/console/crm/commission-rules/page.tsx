'use client';

import { useTranslations } from 'next-intl';
import { Breadcrumb, Card, CardHeader, CardTitle } from '@/design-system/ui';
import { MockDataNotice } from '@/domain/components/mock-data-notice';
import { CRM_IS_MOCK } from '@/features/crm/api';
import { RuleList } from '@/domain/components/rule-list';
import { useCommissionRules } from '@/features/crm/api/queries';
import { partyLabelKey } from '@/features/crm/constants';

/** Screen #119 — Commission rules. FR-CRM-008. Read-only — see MI-31. */
export default function CommissionRulesPage() {
  const t = useTranslations('crm');
  const { data: rules, isLoading } = useCommissionRules();

  return (
    <div className="flex flex-col gap-4">
      <MockDataNotice active={CRM_IS_MOCK} />
      <Breadcrumb
        label={t('breadcrumbLabel')}
        items={[
          { label: t('commissions.title'), href: '/console/crm/commissions' },
          { label: t('commissionRules.title') },
        ]}
      />
      <h1 className="text-xl font-semibold">{t('commissionRules.title')}</h1>

      <Card record="money">
        <CardHeader><CardTitle>{t('commissionRules.subtitle')}</CardTitle></CardHeader>
        <RuleList
          rules={rules?.map((rule) => ({
            id: rule.id, name: rule.name, kind: rule.party,
            condition: rule.condition, priority: rule.priority, enabled: rule.enabled,
          }))}
          isLoading={isLoading}
          kindLabel={(kind) => t(partyLabelKey(kind))}
          editorNotice={{
            title: t('rules.editorBlockedTitle'),
            body: t('rules.editorBlockedBody'),
          }}
        />
      </Card>
    </div>
  );
}
