import { Box, Button, LabeledList, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Data = {
  patient: string | null;
  payload: string | null;
  operating: boolean;
  open: boolean;
  status: string;
  duration: number;
};

export const Autodoc = () => {
  const { act, data } = useBackend<Data>();
  const { patient, payload, operating, open, status, duration } = data;

  return (
    <Window width={460} height={430} title="Autodoc">
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Section title="Automated Surgical Capsule">
              <LabeledList>
                <LabeledList.Item label="Patient">
                  {patient || 'None'}
                </LabeledList.Item>
                <LabeledList.Item label="Loaded Item">
                  {payload || 'None'}
                </LabeledList.Item>
                <LabeledList.Item label="Chamber">
                  {open ? 'Open' : 'Closed'}
                </LabeledList.Item>
                <LabeledList.Item label="Procedure Time">
                  {duration} seconds
                </LabeledList.Item>
              </LabeledList>
              <Box mt={2} color={operating ? 'average' : 'label'}>
                {status}
              </Box>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Section title="Patient and Supplies">
              <Box mb={1}>
                Load a limb, organ, filled implanter, or implant case by using
                the item on the machine.
              </Box>
              <Stack>
                <Stack.Item>
                  <Button
                    icon="sign-in-alt"
                    disabled={operating || !!patient || !open}
                    onClick={() => act('enter')}
                  >
                    Enter Chamber
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="door-open"
                    disabled={operating || !patient}
                    onClick={() => act('exit')}
                  >
                    Open / Exit
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="eject"
                    disabled={operating || !payload}
                    onClick={() => act('eject')}
                  >
                    Eject Item
                  </Button>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Section title="Surgical Procedure">
              <Button
                fluid
                bold
                icon="heartbeat"
                color="green"
                disabled={operating || !patient || !payload || open}
                onClick={() => act('start')}
              >
                {operating ? 'Operating...' : 'Begin 10-Second Surgery'}
              </Button>
              <Button
                fluid
                mt={1}
                icon="trash"
                color="red"
                disabled={operating || !patient || open}
                onClick={() => act('remove_implants')}
              >
                Remove All Implants
              </Button>
              <Box mt={1} color="label">
                An implant is installed, an organ is replaced in its slot, or a
                limb is swapped at its matching body zone.
              </Box>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
