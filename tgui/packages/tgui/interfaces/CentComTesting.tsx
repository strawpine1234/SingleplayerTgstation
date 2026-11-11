import { useState } from 'react';
import {
  Box,
  Button,
  Input,
  NoticeBox,
  Section,
  Stack,
  Table,
  Tabs,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Trial = {
  id: string;
  name: string;
  description: string;
  category: string;
  severity: string;
  blocked: string | null;
};

type Data = { events: Trial[]; status: string };
const severities = ['Minor', 'Moderate', 'Major', 'Catastrophic'];

export const CentComTesting = () => {
  const { act, data } = useBackend<Data>();
  const [severity, setSeverity] = useState('Minor');
  const [search, setSearch] = useState('');
  const events = data.events
    .filter(
      (event) =>
        event.severity === severity &&
        `${event.name} ${event.category} ${event.description}`
          .toLowerCase()
          .includes(search.toLowerCase()),
    )
    .sort((a, b) => a.name.localeCompare(b.name));

  return (
    <Window width={900} height={680}>
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <NoticeBox>{data.status}</NoticeBox>
            <Box color="label" mb={1}>
              Automated station events are suspended. Central Command authorizes
              live trials at your request. Volunteer-dependent tests need
              available ghosts; equipment-dependent tests need the relevant
              station systems.
            </Box>
            <Tabs>
              {severities.map((band) => (
                <Tabs.Tab
                  key={band}
                  selected={severity === band}
                  onClick={() => setSeverity(band)}
                >
                  {band}
                </Tabs.Tab>
              ))}
            </Tabs>
            <Input
              fluid
              placeholder="Search trials..."
              value={search}
              onChange={setSearch}
            />
          </Stack.Item>
          <Stack.Item grow>
            <Section
              title={`${severity} trials (${events.length})`}
              fill
              scrollable
            >
              {events.length === 0 && (
                <Box color="label">No matching trials.</Box>
              )}
              <Table>
                {events.map((event) => (
                  <Table.Row key={event.id}>
                    <Table.Cell py={1}>
                      <Box bold>{event.name}</Box>
                      <Box color="label" fontSize="0.9em">
                        {event.category}
                      </Box>
                      <Box mt={0.5} mr={2}>
                        {event.description}
                      </Box>
                    </Table.Cell>
                    <Table.Cell collapsing textAlign="right">
                      <Button
                        icon="flask"
                        color={severity === 'Catastrophic' ? 'bad' : undefined}
                        disabled={!!event.blocked}
                        tooltip={
                          event.blocked || 'Authorize this live station trial.'
                        }
                        onClick={() => act('test', { id: event.id })}
                      >
                        Test
                      </Button>
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
