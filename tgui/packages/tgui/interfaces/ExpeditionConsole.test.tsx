import { beforeEach, describe, expect, it } from 'bun:test';
import { fireEvent, render, screen } from '@testing-library/react';

import { gameDataAtom, store } from '../events/store';
import { ExpeditionConsole } from './ExpeditionConsole';

const assignment = (id: string, kind: string, difficulty: number) => ({
  id,
  kind,
  difficulty,
  title: `Assignment ${id}`,
  description: `Brief for ${id}`,
  issuer: 'Central Command',
  orders: ['Follow the assigned beacon.'],
  reward_theme: 'Authorized relics',
  rewards: [
    { id: `reward-${id}`, name: `Relic ${id}`, description: 'A relic.' },
  ],
  work_seconds: 20,
  state: 'offered',
  gps: `EXP-${id}`,
  room: 'Cargo Bay',
  coordinates: '1, 2, 3',
  kills: 0,
  targets: 0,
  recovered: false,
  waves: 0,
  deployment_disabled: false,
});

const offers = [
  assignment('one', 'survey', 1),
  assignment('two', 'salvage', 2),
  assignment('three', 'hunt', 3),
  assignment('raid', 'siege', 4),
  assignment('breach', 'necropolis', 4),
];

beforeEach(() => {
  store.set(gameDataAtom, {
    status: 'Tasking available.',
    completed: 0,
    cooldown: 0,
    active: null,
    offers,
  });
});

describe('Expedition mission tabs', () => {
  it('shows the matching mission when browsing each category', () => {
    render(<ExpeditionConsole />);
    expect(screen.getByText('Assignment one')).toBeDefined();
    const categories = [
      ['T2 Expedition', 'Assignment two'],
      ['T3 Expedition', 'Assignment three'],
      ['Syndicate Signal', 'Assignment raid'],
      ['Lavaland Anomalies', 'Assignment breach'],
      ['T1 Expedition', 'Assignment one'],
    ];
    let previous = 'Assignment one';
    for (const [tab, title] of categories) {
      fireEvent.click(screen.getByText(tab));
      expect(screen.getByText(title)).toBeDefined();
      expect(screen.queryByText(previous)).toBeNull();
      previous = title;
    }
  });

  it('returns to active reward controls after browsing another tab', () => {
    store.set(gameDataAtom, {
      status: 'Requisition clearance granted.',
      completed: 0,
      cooldown: 0,
      active: { ...offers[3], state: 'complete' },
      offers,
    });
    render(<ExpeditionConsole />);
    expect(
      screen.getByText('Central Command Requisition Clearance'),
    ).toBeDefined();
    fireEvent.click(screen.getByText('T1 Expedition'));
    expect(screen.getByText('Assignment one')).toBeDefined();
    expect(
      screen.queryByText('Central Command Requisition Clearance'),
    ).toBeNull();
    fireEvent.click(screen.getByText('View Active Assignment'));
    expect(
      screen.getByText('Central Command Requisition Clearance'),
    ).toBeDefined();
    expect(screen.getByText('Relic raid')).toBeDefined();
    expect(screen.getByText('Withdraw from Assignment')).toBeDefined();
  });
});
