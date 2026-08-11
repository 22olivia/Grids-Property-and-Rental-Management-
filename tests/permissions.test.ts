import { describe, expect, it } from 'vitest';
import { checkPermissions, hasPermission } from '@/lib/permissions/check';
import { permission } from '@/lib/permissions/types';
import { filterNavigation, type NavigationSection } from '@/config/navigation';

const READ = permission('example.read');
const WRITE = permission('example.write');

describe('permission checks', () => {
  it('grants when the permission is held', () => {
    expect(hasPermission([READ], READ)).toBe(true);
    expect(hasPermission([READ], WRITE)).toBe(false);
  });

  it('requires all permissions in "all" mode', () => {
    expect(checkPermissions([READ], [READ, WRITE], 'all')).toBe(false);
    expect(checkPermissions([READ, WRITE], [READ, WRITE], 'all')).toBe(true);
  });

  it('requires one permission in "any" mode', () => {
    expect(checkPermissions([READ], [READ, WRITE], 'any')).toBe(true);
  });

  it('grants when nothing is required', () => {
    expect(checkPermissions([], [], 'all')).toBe(true);
  });

  it('denies everything for an anonymous user', () => {
    expect(checkPermissions([], [READ], 'all')).toBe(false);
    expect(checkPermissions([], [READ], 'any')).toBe(false);
  });
});

describe('navigation filtering', () => {
  const sections: NavigationSection[] = [
    {
      labelKey: 'nav.section',
      items: [
        { labelKey: 'nav.open', href: '/open', permissions: [] },
        { labelKey: 'nav.guarded', href: '/guarded', permissions: [WRITE] },
      ],
    },
    {
      labelKey: 'nav.restricted',
      items: [{ labelKey: 'nav.hidden', href: '/hidden', permissions: [WRITE] }],
    },
  ];

  it('keeps items whose permissions are held', () => {
    const result = filterNavigation(sections, () => true);
    expect(result).toHaveLength(2);
  });

  it('drops sections that end up empty rather than rendering an empty heading', () => {
    const result = filterNavigation(sections, () => false);
    expect(result).toHaveLength(1);
    expect(result[0]?.items.map((item) => item.href)).toEqual(['/open']);
  });
});
