import { describe, expect, it } from 'bun:test';
import { fireEvent, render, screen } from '@testing-library/react';
import { gameDataAtom, store } from '../events/store';
import { OreSilo } from './OreSilo';

describe('Ore silo logs', () => {
  it('renders, searches and expands a log without user data', () => {
    store.set(gameDataAtom, {
      SHEET_MATERIAL_AMOUNT: 100,
      materials: [],
      machines: [],
      banned_users: [],
      ID_required: false,
      logs: [
        {
          raw_materials: '100 iron',
          machine_name: 'flatpacker',
          area_name: 'Cargo Bay',
          action: 'PROCESSED',
          amount: -1,
          time: '12:00',
          noun: 'design',
          user_data: null,
        },
      ],
    });
    render(
      <OreSilo
        SHEET_MATERIAL_AMOUNT={100}
        materials={[]}
        machines={[]}
        logs={[]}
        banned_users={[]}
        ID_required={false}
      />,
    );
    expect(screen.getByText('Unknown user')).toBeDefined();
    fireEvent.change(
      screen.getByPlaceholderText(
        'Search for names, locations and resources...',
      ),
      { target: { value: 'flatpacker' } },
    );
    expect(screen.getByText('Unknown user')).toBeDefined();
    fireEvent.click(screen.getByText('Unknown user'));
    expect(screen.getByText('No user identity recorded.')).toBeDefined();
    expect(screen.queryByText('Restrict access')).toBeNull();
  });
});
