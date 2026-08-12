import type { Permission } from '@/lib/permissions/types';

/**
 * Role-aware navigation tree.
 *
 * A navigation entry declares the permissions required to see it; the shell
 * filters the tree against the session. A section whose children are all
 * filtered out is hidden entirely, so a user never sees an empty menu.
 *
 * INTENTIONALLY EMPTY.
 *
 * Populating this requires (a) the permission taxonomy, which does not exist
 * in any source document (MI-11), and (b) the approved screen scope, which is
 * still pending the CEO decision between Option A / B / C. Adding entries now
 * would encode both unresolved decisions into the codebase.
 *
 * The structure and the filtering logic are complete and tested — only the
 * data is absent.
 */
export interface NavigationItem {
  /** Message key in the i18n catalogue, never a literal string. */
  labelKey: string;
  href: string;
  /** All must be held to see the item. Empty means always visible. */
  permissions: Permission[];
  children?: NavigationItem[];
}

export interface NavigationSection {
  labelKey: string;
  items: NavigationItem[];
}

/**
 * Console navigation.
 *
 * Only the Property Assets module (E05 / FR-AST-*) is implemented, so only it
 * appears. Entries are added as modules are approved and built — an entry for
 * an unbuilt screen is a broken link, not a roadmap.
 *
 * `permissions: []` means "always visible". This is NOT a decision that these
 * screens are unrestricted — it is a consequence of MI-11: no permission
 * taxonomy exists in any source document, so there is no string to require
 * yet. The filtering machinery is complete and tested; populating these arrays
 * is a one-line change per entry once the taxonomy is published.
 */
export const consoleNavigation: NavigationSection[] = [
  {
    labelKey: 'ast.module',
    items: [
      { labelKey: 'ast.properties.title', href: '/console/assets/properties', permissions: [] },
      { labelKey: 'ast.buildings.title', href: '/console/assets/buildings', permissions: [] },
      { labelKey: 'ast.units.title', href: '/console/assets/units', permissions: [] },
    ],
  },
  {
    labelKey: 'lst.module',
    items: [
      { labelKey: 'lst.listings.title', href: '/console/listings', permissions: [] },
      { labelKey: 'lst.approvals.title', href: '/console/listings/approvals', permissions: [] },
      { labelKey: 'lst.projects.title', href: '/console/listings/projects', permissions: [] },
    ],
  },
  {
    labelKey: 'crm.module',
    items: [
      { labelKey: 'crm.leads.title', href: '/console/crm/leads', permissions: [] },
      { labelKey: 'crm.pipeline.title', href: '/console/crm/pipeline', permissions: [] },
      { labelKey: 'crm.activities.title', href: '/console/crm/activities', permissions: [] },
      { labelKey: 'crm.viewings.title', href: '/console/crm/viewings', permissions: [] },
      { labelKey: 'crm.offers.title', href: '/console/crm/offers', permissions: [] },
      { labelKey: 'crm.deals.title', href: '/console/crm/deals', permissions: [] },
      { labelKey: 'crm.commissions.title', href: '/console/crm/commissions', permissions: [] },
      { labelKey: 'crm.assignmentRules.title', href: '/console/crm/assignment-rules', permissions: [] },
      { labelKey: 'crm.commissionRules.title', href: '/console/crm/commission-rules', permissions: [] },
    ],
  },
];
export const portalNavigation: NavigationSection[] = [];

/**
 * Filter a navigation tree against granted permissions.
 * Empty sections are dropped rather than rendered as empty headings.
 */
export function filterNavigation(
  sections: NavigationSection[],
  can: (required: Permission | Permission[]) => boolean,
): NavigationSection[] {
  return sections
    .map((section) => ({
      ...section,
      items: section.items
        .filter((item) => item.permissions.length === 0 || can(item.permissions))
        .map((item) => ({
          ...item,
          children: item.children?.filter(
            (child) => child.permissions.length === 0 || can(child.permissions),
          ),
        })),
    }))
    .filter((section) => section.items.length > 0);
}
