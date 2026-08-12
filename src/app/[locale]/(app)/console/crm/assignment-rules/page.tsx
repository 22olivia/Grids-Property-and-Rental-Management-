'use client';

import { useTranslations } from 'next-intl';
import { Breadcrumb, Card, CardHeader, CardTitle } from '@/design-system/ui';
import { MockDataNotice } from '@/domain/components/mock-data-notice';
import { CRM_IS_MOCK } from '@/features/crm/api';
import { RuleList } from '@/domain/components/rule-list';
import { useAssignmentRules } from '@/features/crm/api/queries';
import { basisLabelKey } from '@/features/crm/constants';

/** Screen #110 — Assignment rules. FR-CRM-002. Read-only — see MI-31. */
export default function AssignmentRulesPage() {
  const t = useTranslations('crm');
  const { data: rules, isLoading } = useAssignmentRules();

  return (
    <div className="flex flex-col gap-4">
      <MockDataNotice active={CRM_IS_MOCK} />
      <Breadcrumb
        label={t('breadcrumbLabel')}
        items={[{ label: t('leads.title'), href: '/console/crm/leads' }, { label: t('assignmentRules.title') }]}
      />
      <h1 className="text-xl font-semibold">{t('assignmentRules.title')}</h1>

      <Card record="party">
        <CardHeader><CardTitle>{t('assignmentRules.subtitle')}</CardTitle></CardHeader>
        <RuleList
          rules={rules?.map((rule) => ({
            id: rule.id, name: rule.name, kind: rule.basis,
            condition: rule.condition, priority: rule.priority, enabled: rule.enabled,
          }))}
          isLoading={isLoading}
          kindLabel={(kind) => t(basisLabelKey(kind))}
          editorNotice={{
            title: t('rules.editorBlockedTitle'),
            body: t('rules.editorBlockedBody'),
          }}
        />
      </Card>
    </div>
  );
}
